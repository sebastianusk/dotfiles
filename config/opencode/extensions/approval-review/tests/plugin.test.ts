import { expect, test } from "bun:test";
import { mkdtemp, readFile, realpath, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { compileVibeguardRedactionConfig } from "../lib/config.js";
import type { ApprovalReviewConfig, ApprovalRecord } from "../lib/types.js";
import { ApprovalReviewStore } from "../lib/store.js";
import { createApprovalReviewTools, createEventHook } from "../lib/runtime.js";

const root = await mkdtemp(join(tmpdir(), "approval-review-plugin-"));
const dataPath = join(root, "data");
const configPath = join(root, "opencode.json");
await writeFile(configPath, JSON.stringify({ $schema: "https://opencode.ai/config.json", permission: { bash: { "*": "ask" } } }));

const config = (): ApprovalReviewConfig => ({ dataPath, retentionDays: 90, promotablePermissions: [] });
const redaction = compileVibeguardRedactionConfig({
  enabled: true,
  patterns: { regex: [{ pattern: "SECRET_PATTERN_THAT_NEVER_MATCHES" }] },
});
const store = new ApprovalReviewStore(
  config(),
  redaction.status === "ready" ? redaction.patterns : undefined,
  "testproject",
);
await store.initialize();

const hooks = { event: createEventHook(store) };
const tools = createApprovalReviewTools({ store, configPath, promotablePermissions: [] });

const askedEvent = (id: string, command: string) => ({
  type: "permission.asked",
  properties: {
    id,
    sessionID: "session-secret",
    permission: "bash",
    patterns: [command],
    always: [`${command} *`],
    metadata: { command },
  },
});

const repliedEvent = (id: string, reply: string) => ({
  type: "permission.replied",
  properties: { sessionID: "s", requestID: id, reply },
});

const context = {
  sessionID: "s",
  messageID: "m",
  agent: "build",
  directory: "/tmp",
  worktree: "/tmp",
  abort: new AbortController().signal,
  metadata: () => {},
} as any;

async function reviewable(): Promise<ApprovalRecord[]> {
  return store.listReviewable();
}

test("captures an asked/replied pair as a completed record", async () => {
  await hooks.event({ event: askedEvent("request-1", "git status") });
  await hooks.event({ event: repliedEvent("request-1", "once") });
  const records = await reviewable();
  expect(records).toMatchObject([{ id: "request-1", reply: "once", disposition: "unreviewed" }]);
});

test("does not capture the plugin's own confirmation permission", async () => {
  await hooks.event({
    event: {
      type: "permission.asked",
      properties: { id: "self", permission: "approval-review-apply", patterns: ["diff"], always: [], metadata: {} },
    },
  });
  expect((await reviewable()).some((record) => record.id === "self")).toBe(false);
});

test("records nothing when redaction is unavailable", async () => {
  const offlineRoot = join(root, "offline");
  const offlineStore = new ApprovalReviewStore({ ...config(), dataPath: offlineRoot }, undefined);
  await offlineStore.initialize();
  await createEventHook(offlineStore)({ event: askedEvent("offline", "git log") });
  await createEventHook(offlineStore)({ event: repliedEvent("offline", "once") });
  expect(await offlineStore.listReviewable()).toEqual([]);
});

test("a rejected apply confirmation changes neither config nor dispositions", async () => {
  await hooks.event({ event: askedEvent("request-2", "eza --long") });
  await hooks.event({ event: repliedEvent("request-2", "once") });
  const before = await readFile(configPath, "utf8");
  const candidates = [{ permission: "bash", pattern: "eza --long", action: "allow" as const, evidenceIds: ["request-2"] }];
  await expect(tools.approval_review_apply.execute(
    { candidates },
    { ...context, ask: async () => { throw new Error("Rejected"); } },
  )).rejects.toThrow("Rejected");
  expect(await readFile(configPath, "utf8")).toBe(before);
  expect((await reviewable())[0].disposition).toBe("unreviewed");
});

test("aborts when config changed after preview", async () => {
  const candidates = [{ permission: "bash", pattern: "eza --long", action: "allow" as const, evidenceIds: ["request-2"] }];
  await expect(tools.approval_review_apply.execute(
    { candidates },
    { ...context, ask: async () => { await writeFile(configPath, '{"changed":true,"permission":{}}'); } },
  )).rejects.toThrow("changed");
  // restore fixture for the next test
  await writeFile(configPath, JSON.stringify({ $schema: "https://opencode.ai/config.json", permission: { bash: { "*": "ask" } } }));
});

test("an approved apply writes the minimal rule through the symlink target and handles evidence", async () => {
  const linkedTarget = join(root, "real-opencode.json");
  await writeFile(linkedTarget, '{\n  // models omitted\n  "permission": { "bash": { "*": "ask" } }\n}\n');
  const symlinkPath = join(root, "linked-opencode.json");
  await Bun.write(symlinkPath, Bun.file(linkedTarget)).catch(() => {});
  await Bun.$`ln -sf ${linkedTarget} ${symlinkPath}`.quiet();

  const linkedTools = createApprovalReviewTools({
    store,
    configPath: symlinkPath,
    promotablePermissions: [],
  });
  const candidates = [{ permission: "bash", pattern: "eza --long", action: "allow" as const, evidenceIds: ["request-2"] }];
  await linkedTools.approval_review_apply.execute({ candidates }, { ...context, ask: async () => undefined });

  const written = JSON.parse((await readFile(linkedTarget, "utf8")).replace(/^\s*\/\/.*$/gm, ""));
  expect(written.permission.bash["eza --long"]).toBe("allow");
  expect(written.permission.bash["*"]).toBe("ask");
  expect(await readFile(linkedTarget, "utf8")).toContain("// models omitted");
  expect(Bun.$`readlink ${symlinkPath}`.text() !== undefined).toBe(true);
  const applied = JSON.parse(await readFile(join(dataPath, "records", "request-2.json"), "utf8"));
  expect(applied.disposition).toBe("rule-applied");
});

test("list tool groups records; validate returns patch preview", async () => {
  await hooks.event({ event: askedEvent("request-3", "rg foo") });
  await hooks.event({ event: repliedEvent("request-3", "always") });
  const listed = JSON.parse(await tools.approval_review_list.execute({}, context) as string);
  expect(listed.total >= 1).toBe(true);

  const validated = JSON.parse(await tools.approval_review_validate.execute({
    candidates: [{ permission: "bash", pattern: "rg foo", action: "allow", evidenceIds: ["request-3"] }],
  }, context) as string);
  expect(validated.results[0].validation.valid).toBe(true);
  expect(validated.patch.after).toContain('"rg foo": "allow"');
});
