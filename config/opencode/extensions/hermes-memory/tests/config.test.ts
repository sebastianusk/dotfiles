import { expect, test } from "bun:test";
import { homedir } from "node:os";
import { parseConfig } from "../lib/config.js";

test("uses safe local defaults and accepts explicit bounded settings", () => {
  expect(parseConfig(`{
    // local-only review
    "dataPath": "~/.local/share/opencode/hermes-memory",
    "ollamaModel": "qwen3:14b",
    "reviewEveryTurns": 10
  }`)).toMatchObject({
    dataPath: `${homedir()}/.local/share/opencode/hermes-memory`,
    ollamaUrl: "http://127.0.0.1:11434",
    ollamaModel: "qwen3:14b",
    reviewEveryTurns: 10,
    minConfidence: 0.9,
    maxTranscriptChars: 12000,
  });
});

test("rejects remote review endpoints and invalid cadences", () => {
  expect(() => parseConfig('{"ollamaUrl":"http://example.com"}')).toThrow("loopback");
  expect(() => parseConfig('{"ollamaUrl":"https://127.0.0.1:11434"}')).toThrow("http");
  expect(() => parseConfig('{"reviewEveryTurns":0}')).toThrow("reviewEveryTurns");
});
