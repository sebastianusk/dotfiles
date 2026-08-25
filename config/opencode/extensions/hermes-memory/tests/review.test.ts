import { expect, test } from "bun:test";
import { mkdtemp, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { MemoryReviewScheduler } from "../lib/review.js";
import { MemoryStore } from "../lib/store.js";

test("stages local-review candidates only after the configured turn cadence", async () => {
  const root = await mkdtemp(join(tmpdir(), "hermes-memory-review-"));
  try {
    const store = new MemoryStore(root, { userCharLimit: 100, globalCharLimit: 100, projectCharLimit: 100 });
    const scheduler = new MemoryReviewScheduler({ store, reviewEveryTurns: 2, minIntervalMs: 0 });
    const reviewer = async () => [{ target: "user" as const, operation: "add" as const, content: "Prefer terse answers.", confidence: 0.9 }];

    await scheduler.recordTurn({ sessionID: "s1", messageID: "m1", projectId: "0123456789abcdef", text: "First" });
    expect(await store.listPending()).toEqual([]);
    await scheduler.recordTurn({ sessionID: "s1", messageID: "m2", projectId: "0123456789abcdef", text: "Second" });
    expect(await store.listPending()).toEqual([]);
    await scheduler.reviewIfDue("s1", reviewer);

    const pending = await store.listPending();
    expect(pending).toHaveLength(1);
    expect(pending[0]).toMatchObject({ content: "Prefer terse answers.", sourceSessionIds: ["s1"], sourceMessageIds: ["m1", "m2"] });
    expect(await store.read("user")).toEqual([]);
  } finally {
    await rm(root, { recursive: true, force: true });
  }
});

test("does not let one session trigger review of another session", async () => {
  const root = await mkdtemp(join(tmpdir(), "hermes-memory-review-"));
  try {
    const store = new MemoryStore(root, { userCharLimit: 100, globalCharLimit: 100, projectCharLimit: 100 });
    const scheduler = new MemoryReviewScheduler({ store, reviewEveryTurns: 2, minIntervalMs: 0 });
    const reviewer = async () => [{ target: "memory" as const, operation: "add" as const, content: "Project fact.", confidence: 0.9 }];
    await scheduler.recordTurn({ sessionID: "s1", messageID: "m1", projectId: "0123456789abcdef", text: "One" });
    await scheduler.recordTurn({ sessionID: "s1", messageID: "m2", projectId: "0123456789abcdef", text: "Two" });
    await scheduler.recordTurn({ sessionID: "s2", messageID: "m3", projectId: "fedcba9876543210", text: "Other" });

    expect(await scheduler.reviewIfDue("s2", reviewer)).toBe(0);
    expect(await scheduler.reviewIfDue("s1", reviewer)).toBe(1);
  } finally {
    await rm(root, { recursive: true, force: true });
  }
});

test("retains due turns when local review fails so a later idle review can retry", async () => {
  const root = await mkdtemp(join(tmpdir(), "hermes-memory-review-"));
  try {
    const store = new MemoryStore(root, { userCharLimit: 100, globalCharLimit: 100, projectCharLimit: 100 });
    const scheduler = new MemoryReviewScheduler({ store, reviewEveryTurns: 1, minIntervalMs: 0 });
    await scheduler.recordTurn({ sessionID: "s1", messageID: "m1", projectId: "0123456789abcdef", text: "One" });
    await expect(scheduler.reviewIfDue("s1", async () => { throw new Error("Ollama unavailable"); })).rejects.toThrow("Ollama unavailable");

    expect(await scheduler.reviewIfDue("s1", async () => [{ target: "memory", operation: "add", content: "Retried.", confidence: 1 }])).toBe(1);
  } finally {
    await rm(root, { recursive: true, force: true });
  }
});

test("preserves turns recorded while an in-flight review is waiting", async () => {
  const root = await mkdtemp(join(tmpdir(), "hermes-memory-review-"));
  try {
    const store = new MemoryStore(root, { userCharLimit: 100, globalCharLimit: 100, projectCharLimit: 100 });
    const scheduler = new MemoryReviewScheduler({ store, reviewEveryTurns: 1, minIntervalMs: 0 });
    let release!: () => void;
    const wait = new Promise<void>((resolve) => { release = resolve; });
    await scheduler.recordTurn({ sessionID: "s1", messageID: "m1", projectId: "0123456789abcdef", text: "First" });
    const running = scheduler.reviewIfDue("s1", async () => {
      await wait;
      return [{ target: "memory" as const, operation: "add" as const, content: "First fact.", confidence: 1 }];
    });
    await scheduler.recordTurn({ sessionID: "s1", messageID: "m2", projectId: "0123456789abcdef", text: "Second" });
    release();
    await running;

    expect(await scheduler.reviewIfDue("s1", async () => [{ target: "memory", operation: "add", content: "Second fact.", confidence: 1 }])).toBe(1);
  } finally {
    await rm(root, { recursive: true, force: true });
  }
});

test("stages only high-confidence candidates from a bounded recent transcript", async () => {
  const root = await mkdtemp(join(tmpdir(), "hermes-memory-review-"));
  try {
    const store = new MemoryStore(root, { userCharLimit: 100, globalCharLimit: 100, projectCharLimit: 100 });
    const scheduler = new MemoryReviewScheduler({ store, reviewEveryTurns: 1, minIntervalMs: 0, minConfidence: 0.9, maxTranscriptChars: 20 });
    await scheduler.recordTurn({ sessionID: "s1", messageID: "m1", projectId: "0123456789abcdef", text: "old context that must not be included" });
    await scheduler.recordTurn({ sessionID: "s1", messageID: "m2", projectId: "0123456789abcdef", text: "recent" });
    let transcript = "";

    await scheduler.flush("s1", async (value) => {
      transcript = value;
      return [
        { target: "user", operation: "add", content: "Prefer terse answers.", confidence: 0.95 },
        { target: "user", operation: "add", content: "Weak inference.", confidence: 0.2 },
      ];
    });

    expect(transcript).toBe("User: recent");
    expect((await store.listPending()).map((item) => item.content)).toEqual(["Prefer terse answers."]);
  } finally {
    await rm(root, { recursive: true, force: true });
  }
});
