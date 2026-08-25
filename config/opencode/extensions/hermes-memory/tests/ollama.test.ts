import { expect, test } from "bun:test";
import { reviewTranscript } from "../lib/ollama.js";

test("returns only valid local-model memory candidates", async () => {
  const fetcher = async () => new Response(JSON.stringify({
    message: {
      content: JSON.stringify({
        candidates: [{
          target: "user",
          operation: "add",
          content: "Prefer terse answers.",
          confidence: 0.92,
        }],
      }),
    },
  }));

  await expect(reviewTranscript({
    baseUrl: "http://127.0.0.1:11434",
    model: "qwen3:14b",
    transcript: "User: Keep answers terse.",
    fetcher,
  })).resolves.toEqual([{ target: "user", operation: "add", content: "Prefer terse answers.", confidence: 0.92 }]);
});

test("refuses a non-loopback Ollama endpoint", async () => {
  await expect(reviewTranscript({
    baseUrl: "http://example.com",
    model: "qwen3:14b",
    transcript: "User: Prefer terse answers.",
  })).rejects.toThrow("must be loopback");
});

test("refuses HTTPS even when the hostname is loopback", async () => {
  await expect(reviewTranscript({
    baseUrl: "https://127.0.0.1:11434",
    model: "qwen3:14b",
    transcript: "User: Prefer terse answers.",
  })).rejects.toThrow("must use http");
});

test("rejects malformed model output instead of creating candidates", async () => {
  const fetcher = async () => new Response(JSON.stringify({ message: { content: "not JSON" } }));
  await expect(reviewTranscript({
    baseUrl: "http://127.0.0.1:11434",
    model: "qwen3:14b",
    transcript: "User: Prefer terse answers.",
    fetcher,
  })).rejects.toThrow("valid JSON");
});

test("does not follow redirects away from the loopback endpoint", async () => {
  const fetcher = async (_input: RequestInfo | URL, init?: RequestInit) => {
    expect(init?.redirect).toBe("error");
    return new Response(JSON.stringify({ message: { content: '{"candidates":[]}' } }));
  };
  await reviewTranscript({ baseUrl: "http://127.0.0.1:11434", model: "qwen3:14b", transcript: "Nothing durable.", fetcher });
});

test("rejects non-add model mutations because they need explicit prior content", async () => {
  const fetcher = async () => new Response(JSON.stringify({
    message: { content: JSON.stringify({ candidates: [{ target: "memory", operation: "remove", content: "Old fact", confidence: 0.9 }] }) },
  }));
  await expect(reviewTranscript({ baseUrl: "http://127.0.0.1:11434", model: "qwen3:14b", transcript: "Remove an old fact.", fetcher })).rejects.toThrow("invalid candidate");
});

test("uses a constrained schema and sufficient deterministic context settings", async () => {
  const fetcher = async (_input: RequestInfo | URL, init?: RequestInit) => {
    const body = JSON.parse(String(init?.body));
    expect(body.format.properties.candidates.items.properties.target.enum).toEqual(["user", "memory", "project"]);
    expect(body.format.properties.candidates.items.properties.operation.enum).toEqual(["add"]);
    expect(body.options).toEqual({ num_ctx: 16384, num_predict: 1024, temperature: 0 });
    expect(body.think).toBe(false);
    expect(body.truncate).toBe(true);
    return new Response(JSON.stringify({ message: { content: '{"candidates":[]}' } }));
  };
  await reviewTranscript({ baseUrl: "http://127.0.0.1:11434", model: "qwen3:14b", transcript: "Nothing durable.", fetcher });
});
