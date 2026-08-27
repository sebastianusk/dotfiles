import { expect, test } from "bun:test";
import { matches } from "../lib/wildcard.js";

test("treats a trailing space wildcard as an optional argument list", () => {
  expect(matches("git status", "git status *")).toBe(true);
  expect(matches("git status --short", "git status *")).toBe(true);
  expect(matches("git statusx", "git status *")).toBe(false);
});

test("supports question and star wildcards without treating regex characters specially", () => {
  expect(matches("read file.t", "read file.?" )).toBe(true);
  expect(matches("read file.ts", "read file.?" )).toBe(false);
  expect(matches("node (script).js", "node (script).js")).toBe(true);
  expect(matches("node script.js", "node (script).js")).toBe(false);
});

test("normalizes backslashes and anchors the whole string", () => {
  expect(matches(String.raw`src\file.ts`, "src/file.ts")).toBe(true);
  expect(matches("git status extra", "git status")).toBe(false);
  expect(matches("xgit status", "git status")).toBe(false);
});

test("matches shell chaining examples literally unless they are wildcards", () => {
  expect(matches("printf '%s' && git status", "printf '%s' && git status")).toBe(true);
  expect(matches("printf '%s' || git status", "printf '%s' || git status")).toBe(true);
  expect(matches("printf '%s' ; git status", "printf '%s' ; git status")).toBe(true);
  expect(matches("printf '%s' | git status", "printf '%s' | git status")).toBe(true);
  expect(matches("printf '%s' && git status", "printf '%s' || git status")).toBe(false);
});
