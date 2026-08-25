import { expect, test } from "bun:test";
import { MemorySessionInjector } from "../lib/context.js";

test("retries memory injection when the first asynchronous load fails", async () => {
  const injector = new MemorySessionInjector();
  await expect(injector.load("session-1", async () => { throw new Error("disk unavailable"); })).rejects.toThrow("disk unavailable");
  await expect(injector.load("session-1", async () => ({ user: ["Prefer terse answers."], global: [], project: [], pendingCount: 0 }))).resolves.toContain("Prefer terse answers.");
});

test("injects memory only once when concurrent transforms load the same session", async () => {
  const injector = new MemorySessionInjector();
  let release!: () => void;
  const wait = new Promise<void>((resolve) => { release = resolve; });
  const loader = async () => {
    await wait;
    return { user: ["Prefer terse answers."], global: [], project: [], pendingCount: 0 };
  };

  const first = injector.load("session-1", loader);
  const second = injector.load("session-1", loader);
  release();
  expect(await first).toContain("Prefer terse answers.");
  expect(await second).toBeUndefined();
});
