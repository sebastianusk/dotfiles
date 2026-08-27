import { expect, test } from "bun:test";
import { redact } from "../lib/redact.js";

test("replaces every configured secret match before persistence", () => {
  expect(redact("curl -H 'Authorization: sk-secret'", [/sk-[^\s']+/g]))
    .toBe("curl -H 'Authorization: [REDACTED]'");
});

test("leaves nonmatching values unchanged", () => {
  expect(redact("git status --short", [/sk-[^\s']+/g])).toBe("git status --short");
});

test("normalizes non-global patterns before replacing every match", () => {
  expect(redact("sk-first sk-second", [/sk-[^\s]+/])).toBe("[REDACTED] [REDACTED]");
});

test("removes sticky matching so every secret is redacted", () => {
  expect(redact("sk-first sk-second", [/sk-\w+/y])).toBe("[REDACTED] [REDACTED]");
});

test("redacts literal keyword patterns", () => {
  expect(redact("literal-secret literal-secret", [/literal-secret/g])).toBe("[REDACTED] [REDACTED]");
});
