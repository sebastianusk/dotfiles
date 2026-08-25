import { expect, test } from "bun:test";
import { mkdir, mkdtemp, readFile, rm, stat, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { MemoryStore } from "../lib/store.js";

async function withStore(run: (store: MemoryStore, root: string) => Promise<void>) {
  const root = await mkdtemp(join(tmpdir(), "hermes-memory-test-"));
  try {
    await run(new MemoryStore(root, { userCharLimit: 100, globalCharLimit: 100, projectCharLimit: 100 }), root);
  } finally {
    await rm(root, { recursive: true, force: true });
  }
}

test("stages mutations until explicitly approved", async () => {
  await withStore(async (store) => {
    const pending = await store.stage({
      operation: "add",
      target: "user",
      content: "Prefer terse bullet-point answers.",
      sourceSessionIds: ["session-1"],
      sourceMessageIds: ["message-1"],
      confidence: 0.9,
    });

    expect(await store.read("user")).toEqual([]);
    await store.approve(pending.id);
    expect(await store.read("user")).toEqual(["Prefer terse bullet-point answers."]);
  });
});

test("records replaced content in provenance", async () => {
  await withStore(async (store, root) => {
    const first = await store.stage({
      operation: "add",
      target: "memory",
      content: "Use npm for this project.",
      sourceSessionIds: ["s1"],
      sourceMessageIds: ["m1"],
      confidence: 0.8,
    });
    await store.approve(first.id);
    const replacement = await store.stage({
      operation: "replace",
      target: "memory",
      content: "Use Bun for this project.",
      previousContent: "Use npm for this project.",
      sourceSessionIds: ["s2"],
      sourceMessageIds: ["m2"],
      confidence: 0.95,
    });

    await store.approve(replacement.id);
    expect(await store.read("memory")).toEqual(["Use Bun for this project."]);
    expect(await readFile(join(root, "provenance.jsonl"), "utf8")).toContain("Use npm for this project.");
  });
});

test("rejects a staged mutation without changing memory", async () => {
  await withStore(async (store) => {
    const pending = await store.stage({
      operation: "add",
      target: "memory",
      content: "Temporary debugging fact.",
      sourceSessionIds: ["s1"],
      sourceMessageIds: ["m1"],
      confidence: 0.5,
    });
    await store.reject(pending.id);
    expect(await store.read("memory")).toEqual([]);
    expect(await store.listPending()).toEqual([]);
  });
});

test("restores memory when provenance recording fails", async () => {
  await withStore(async (store, root) => {
    await mkdir(join(root, "provenance.jsonl"));
    const pending = await store.stage({
      operation: "add",
      target: "memory",
      content: "Never persist a half-approved mutation.",
      sourceSessionIds: ["s1"],
      sourceMessageIds: ["m1"],
      confidence: 0.9,
    });

    await expect(store.approve(pending.id)).rejects.toThrow();
    expect(await store.read("memory")).toEqual([]);
    expect((await store.listPending()).map((item) => item.id)).toEqual([pending.id]);
  });
});

test("serializes concurrent approvals", async () => {
  await withStore(async (store) => {
    const first = await store.stage({ operation: "add", target: "memory", content: "First.", sourceSessionIds: ["s1"], sourceMessageIds: ["m1"], confidence: 1 });
    const second = await store.stage({ operation: "add", target: "memory", content: "Second.", sourceSessionIds: ["s2"], sourceMessageIds: ["m2"], confidence: 1 });

    await Promise.all([store.approve(first.id), store.approve(second.id)]);
    expect(await store.read("memory")).toEqual(["First.", "Second."]);
  });
});

test("rejects project path traversal", async () => {
  await withStore(async (store) => {
    await expect(store.stage({
      operation: "add",
      target: "project",
      projectId: "../../outside",
      content: "Must remain inside the store.",
      sourceSessionIds: ["s1"],
      sourceMessageIds: ["m1"],
      confidence: 1,
    })).rejects.toThrow("Invalid project id");
  });
});

test("rejects additions that exceed the configured target capacity", async () => {
  await withStore(async (store) => {
    const pending = await store.stage({
      operation: "add",
      target: "user",
      content: "x".repeat(101),
      sourceSessionIds: ["s1"],
      sourceMessageIds: ["m1"],
      confidence: 1,
    });
    await expect(store.approve(pending.id)).rejects.toThrow("Memory capacity exceeded");
    expect(await store.read("user")).toEqual([]);
  });
});

test("deduplicates repeated staging of the same proposal", async () => {
  await withStore(async (store) => {
    const proposal = {
      operation: "add" as const,
      target: "memory" as const,
      content: "Keep this once.",
      sourceSessionIds: ["s1"],
      sourceMessageIds: ["m1"],
      confidence: 0.9,
    };
    const first = await store.stage(proposal);
    const second = await store.stage(proposal);
    expect(second.id).toBe(first.id);
    expect(await store.listPending()).toHaveLength(1);
  });
});

test("deduplicates concurrent staging of the same proposal", async () => {
  await withStore(async (store) => {
    const proposal = {
      operation: "add" as const,
      target: "memory" as const,
      content: "Keep concurrent retries once.",
      sourceSessionIds: ["s1"],
      sourceMessageIds: ["m1"],
      confidence: 0.9,
    };
    const staged = await Promise.all(Array.from({ length: 10 }, () => store.stage(proposal)));
    expect(new Set(staged.map((item) => item.id)).size).toBe(1);
    expect(await store.listPending()).toHaveLength(1);
  });
});

test("deduplicates equivalent proposals from different source messages", async () => {
  await withStore(async (store) => {
    const first = await store.stage({ operation: "add", target: "memory", content: "Use Bun for this project.", sourceSessionIds: ["s1"], sourceMessageIds: ["m1"], confidence: 0.9 });
    const second = await store.stage({ operation: "add", target: "memory", content: "Use Bun for this project.", sourceSessionIds: ["s2"], sourceMessageIds: ["m2"], confidence: 0.95 });

    expect(second.id).toBe(first.id);
    expect(await store.listPending()).toHaveLength(1);
  });
});

test("ignores malformed pending files and creates private data", async () => {
  await withStore(async (store, root) => {
    await mkdir(join(root, "pending"), { recursive: true });
    await writeFile(join(root, "pending", "broken.json"), "not json");
    const pending = await store.stage({ operation: "add", target: "user", content: "Prefer focused reviews.", sourceSessionIds: ["s1"], sourceMessageIds: ["m1"], confidence: 1 });

    expect((await store.listPending()).map((item) => item.id)).toEqual([pending.id]);
    expect((await stat(join(root, "pending"))).mode & 0o777).toBe(0o700);
    expect((await stat(join(root, "pending", `${pending.id}.json`))).mode & 0o777).toBe(0o600);
  });
});

test("initialization secures an existing memory root", async () => {
  await withStore(async (store, root) => {
    await store.initialize();
    expect((await stat(root)).mode & 0o777).toBe(0o700);
  });
});
