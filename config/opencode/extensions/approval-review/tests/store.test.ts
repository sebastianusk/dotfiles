import { expect, test, beforeEach, afterEach } from "bun:test";
import { chmod, lstat, mkdir, mkdtemp, readFile, readdir, rm, utimes, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { compileVibeguardRedactionConfig } from "../lib/config.js";
import type { ApprovalReviewConfig, AskedPermission, ApprovalRecord } from "../lib/types.js";
import { ApprovalReviewStore } from "../lib/store.js";

let root: string;
let store: ApprovalReviewStore;

const config = (overrides: Partial<ApprovalReviewConfig> = {}): ApprovalReviewConfig => ({
  dataPath: root,
  retentionDays: 90,
  promotablePermissions: [],
  ...overrides,
});

function redactionPatterns(): RegExp[] {
  const result = compileVibeguardRedactionConfig({
    enabled: true,
    patterns: { regex: [{ pattern: String.raw`sk-[^\s']+` }] },
  });
  if (result.status !== "ready") throw new Error(result.reason);
  return result.patterns;
}

const asked = (id: string, command = "git status"): AskedPermission => ({
  id,
  permission: "bash",
  patterns: [command],
  always: [`${command} *`],
  metadata: { command },
});

async function complete(id: string, command = "git status", reply: "once" | "always" | "reject" = "once") {
  await store.recordAsked(asked(id, command));
  await store.recordReplied(id, reply);
}

async function recordPath(id: string) {
  return join(root, "records", `${id}.json`);
}

beforeEach(async () => {
  root = await mkdtemp(join(tmpdir(), "approval-review-"));
  store = new ApprovalReviewStore(config(), redactionPatterns());
  await store.initialize();
});

afterEach(async () => {
  // The test runner removes its temporary directory on process exit.
});

test("pairs an asked event with a reply and stores no session ID", async () => {
  await store.recordAsked(asked("request-1"));
  await store.recordReplied("request-1", "once");

  expect(await store.listReviewable()).toMatchObject([{ id: "request-1", reply: "once", disposition: "unreviewed" }]);
  expect(JSON.stringify(JSON.parse(await readFile(await recordPath("request-1"), "utf8")))).not.toContain("session-secret");
});

test("marks redacted commands as audit-only", async () => {
  await store.recordAsked(asked("request-2", "curl sk-secret"));
  await store.recordReplied("request-2", "once");

  expect(await store.listReviewable()).toMatchObject([{ command: "curl [REDACTED]", redacted: true }]);
});

test("does not persist when effective redaction patterns are unavailable", async () => {
  const unavailable = new ApprovalReviewStore(config(), undefined);
  await unavailable.initialize();

  await expect(unavailable.recordAsked(asked("unavailable"))).resolves.toMatchObject({ written: false });
  expect(await readdir(join(root, "records"))).toEqual([]);
});

test("only replied records are reviewable for every reply type", async () => {
  await store.recordAsked(asked("pending"));
  await complete("once", "git status", "once");
  await complete("always", "git diff", "always");
  await complete("reject", "git push", "reject");

  expect((await store.listReviewable()).map((record) => [record.id, record.reply])).toEqual([
    ["always", "always"],
    ["once", "once"],
    ["reject", "reject"],
  ]);
});

test("dismissed evidence resurfaces only after a new matching decision", async () => {
  await complete("one");
  await store.setDisposition(["one"], "dismissed");

  expect(await store.listReviewable()).toEqual([]);
  await complete("two");
  expect((await store.listReviewable()).map((record) => record.id)).toEqual(["two"]);
});

test("makes deferred evidence reviewable again on the next manual list", async () => {
  await complete("deferred");
  await store.setDisposition(["deferred"], "deferred");
  expect(await store.listReviewable()).toEqual([]);
  expect((await store.beginReview()).map((record) => record.id)).toEqual(["deferred"]);
});

test("updates a disposition through the lock-held transaction route", async () => {
  await complete("locked-disposition");

  await store.withLock(async (locked) => {
    await locked.setDisposition(["locked-disposition"], "rule-applied", { ruleApplication: true });
  });

  expect(await store.listReviewable()).toEqual([]);
});

test("preserves the first completed reply on duplicate replies", async () => {
  await store.recordAsked(asked("duplicate"));
  await store.recordReplied("duplicate", "once");
  await store.recordReplied("duplicate", "reject");

  expect(await store.listReviewable()).toMatchObject([{ id: "duplicate", reply: "once" }]);
});

test("expires old pending records without listing them", async () => {
  await writeFile(await recordPath("pending-old"), JSON.stringify({ ...record("pending-old"), repliedAt: undefined, reply: undefined, askedAt: "2026-01-01T00:00:00.000Z" }));
  await store.prune(new Date("2026-08-26T00:00:00.000Z"));

  expect(await store.listReviewable()).toEqual([]);
  expect(await Bun.file(await recordPath("pending-old")).exists()).toBe(false);
});

test("refuses rule-applied without an explicit rule application caller", async () => {
  await complete("applied");
  await expect(store.setDisposition(["applied"], "rule-applied")).rejects.toThrow("rule application");
  await store.setDisposition(["applied"], "rule-applied", { ruleApplication: true });
  expect(await store.listReviewable()).toEqual([]);
});

test("prunes completed records older than 90 days but retains current evidence", async () => {
  await writeFile(await recordPath("old"), JSON.stringify({ ...record("old"), repliedAt: "2026-01-01T00:00:00.000Z" }));
  await writeFile(await recordPath("current"), JSON.stringify({ ...record("current"), repliedAt: "2026-08-25T00:00:00.000Z" }));
  await store.prune(new Date("2026-08-26T00:00:00.000Z"));
  expect(await ids()).toEqual(["current"]);
});

test("ignores malformed record files", async () => {
  await writeFile(join(root, "records", "broken.json"), "not json");
  expect(await store.listReviewable()).toEqual([]);
});

test("ignores records with invalid timestamps and removes them during pruning", async () => {
  await writeFile(await recordPath("bad-time"), JSON.stringify({ ...record("bad-time"), askedAt: "not-an-iso-date" }));

  expect(await store.listReviewable()).toEqual([]);
  await store.prune(new Date("2026-08-26T00:00:00.000Z"));
  expect(await Bun.file(await recordPath("bad-time")).exists()).toBe(false);
});

test("rejects a record whose stored ID does not match its filename", async () => {
  await complete("correct");
  await writeFile(await recordPath("mismatch"), JSON.stringify(record("correct")));

  expect((await store.listReviewable()).map((item) => item.id)).toEqual(["correct"]);
  await store.setDisposition(["mismatch"], "dismissed");
  expect(JSON.parse(await readFile(await recordPath("correct"), "utf8"))).toMatchObject({ disposition: "unreviewed" });
  expect(await Bun.file(await recordPath("mismatch")).exists()).toBe(false);
});

test("serializes concurrent replies", async () => {
  await store.recordAsked(asked("race"));
  await Promise.all([store.recordReplied("race", "once"), store.recordReplied("race", "once")]);
  expect(await store.listReviewable()).toHaveLength(1);
});

test("ignores unmatched replies and rejects unsafe IDs", async () => {
  await expect(store.recordReplied("missing", "once")).resolves.toBeUndefined();
  await expect(store.recordAsked({ ...asked("../escape") })).rejects.toThrow("Invalid record id");
});

test("creates private storage", async () => {
  const records = await readdir(join(root, "records"));
  expect(records).toEqual([]);
  const stat = await Bun.file(await recordPath("permissions")).exists().catch(() => false);
  expect(stat).toBe(false);
  await complete("permissions");
  expect((await Bun.$`stat -f %Lp ${root}`.text()).trim()).toBe("700");
  expect((await Bun.$`stat -f %Lp ${await recordPath("permissions")}`.text()).trim()).toBe("600");
});

test("recovers a stale lock before writing", async () => {
  const lock = join(root, ".lock");
  await mkdir(lock, { mode: 0o700 });
  const stale = new Date("2026-08-25T00:00:00.000Z");
  await utimes(lock, stale, stale);

  await complete("stale-lock");
  expect((await store.listReviewable()).map((record) => record.id)).toEqual(["stale-lock"]);
});

test("does not remove a lock acquired after stale recovery", async () => {
  const other = new ApprovalReviewStore(config(), redactionPatterns());
  await other.initialize();
  const lock = join(root, ".lock");
  await mkdir(lock, { mode: 0o700 });
  const stale = new Date("2026-08-25T00:00:00.000Z");
  await utimes(lock, stale, stale);

  let releaseOther!: () => void;
  let otherStarted!: () => void;
  const otherReady = new Promise<void>((resolve) => { otherStarted = resolve; });
  const otherReleased = new Promise<void>((resolve) => { releaseOther = resolve; });
  let otherActive = false;
  let overlapped = false;
  let otherOperation!: Promise<void>;
  const recovering = new ApprovalReviewStore(config(), redactionPatterns(), "project", {
    onStaleLockRecovered: async () => {
      otherOperation = other.withLock(async () => {
        otherActive = true;
        otherStarted();
        await otherReleased;
        otherActive = false;
      });
      await otherReady;
      releaseOther();
      await otherOperation;
    },
  });

  let recoveringActive = false;
  await recovering.withLock(async () => {
    overlapped = otherActive;
    recoveringActive = true;
  });
  expect(recoveringActive).toBe(true);
  expect(overlapped).toBe(false);
});

test("does not release a replacement lock after the original path is replaced", async () => {
  const lock = join(root, ".lock");
  let replacement!: { dev: number; ino: number };

  await store.withLock(async () => {
    await rm(lock, { recursive: true, force: true });
    await mkdir(lock, { mode: 0o700 });
    replacement = await lstat(lock);
  });

  const current = await lstat(lock);
  expect({ dev: current.dev, ino: current.ino }).toEqual({ dev: replacement.dev, ino: replacement.ino });
  await rm(lock, { recursive: true, force: true });
});

test("does not continue stale recovery after the acquisition deadline", async () => {
  const lock = join(root, ".lock");
  const stale = new Date("2026-08-25T00:00:00.000Z");
  await mkdir(lock, { mode: 0o700 });
  await utimes(lock, stale, stale);
  let clock = Date.parse("2026-08-26T00:00:00.000Z");
  let recoveries = 0;
  const bounded = new ApprovalReviewStore(config(), redactionPatterns(), "project", {
    now: () => clock,
    onStaleLockRecovered: async () => {
      recoveries += 1;
      clock += 6_000;
      if (recoveries === 1) {
        await mkdir(lock, { mode: 0o700 });
        await utimes(lock, stale, stale);
      }
    },
  });

  await expect(bounded.withLock(async () => undefined)).rejects.toThrow("Timed out");
  expect(recoveries).toBe(1);
});

function record(id: string): ApprovalRecord {
  return { id, permission: "bash", patterns: ["git status"], always: ["git status *"], projectId: "project", askedAt: "2026-01-01T00:00:00.000Z", repliedAt: "2026-01-01T00:00:00.000Z", reply: "once", disposition: "unreviewed", redacted: false };
}

async function ids() {
  return (await readdir(join(root, "records"))).filter((name) => name.endsWith(".json")).map((name) => name.slice(0, -5)).sort();
}
