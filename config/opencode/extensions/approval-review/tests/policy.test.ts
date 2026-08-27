import { expect, test } from "bun:test";
import type { ApprovalRecord, RuleCandidate } from "../lib/types.js";
import { buildPolicyPatch, validateCandidate } from "../lib/policy.js";

function candidate(permission: string, pattern: string, action: "allow" | "deny", evidenceIds: string[] = ["one"]): RuleCandidate {
  return { permission, pattern, action, evidenceIds, explanation: "test" };
}

function completed(id: string, pattern: string, reply: "once" | "always" | "reject", permission = "bash", redacted = false, disposition: ApprovalRecord["disposition"] = "unreviewed"): ApprovalRecord {
  return {
    id, permission, patterns: [pattern], always: [], command: permission === "bash" ? pattern : undefined, projectId: "project", askedAt: "2026-08-27T00:00:00.000Z",
    repliedAt: "2026-08-27T00:00:01.000Z", reply, disposition, redacted,
  };
}

test("blocks an allow wildcard that reaches rejected evidence", () => {
  const result = validateCandidate(candidate("bash", "git push", "allow", ["allowed"]), [
    completed("allowed", "git push", "once"), completed("rejected", "git push", "reject"),
  ], ["bash"]);
  expect(result).toMatchObject({ valid: false, conflictingEvidenceIds: ["rejected"] });
});

test("rejects bare wildcard, redacted evidence, and nonpromotable permissions", () => {
  expect(validateCandidate(candidate("bash", "*", "allow"), [completed("one", "git status", "once")], ["bash"]).valid).toBe(false);
  expect(validateCandidate(candidate("bash", "curl *", "allow", ["secret"]), [completed("secret", "curl [REDACTED]", "once", "bash", true)], ["bash"]).valid).toBe(false);
  expect(validateCandidate(candidate("hermes-memory-approval", "x", "deny", ["custom"]), [completed("custom", "x", "reject", "hermes-memory-approval")], ["bash"]).valid).toBe(false);
});

test("requires selected evidence to be completed, same permission, and promotable", () => {
  expect(validateCandidate(candidate("edit", "src/*.ts", "allow", ["pending"]), [{ ...completed("pending", "src/a.ts", "once", "edit"), reply: undefined, repliedAt: undefined }], ["edit"]).valid).toBe(false);
  expect(validateCandidate(candidate("edit", "src/*.ts", "allow", ["other"]), [completed("other", "src/a.ts", "once", "bash")], ["edit"]).valid).toBe(false);
  expect(validateCandidate(candidate("edit", "src/*.ts", "allow", ["dismissed"]), [completed("dismissed", "src/a.ts", "once", "edit", false, "dismissed")], ["edit"]).valid).toBe(false);
  expect(validateCandidate(candidate("approval-review-apply", "x", "deny", ["plugin"]), [completed("plugin", "x", "reject", "approval-review-apply")], ["approval-review-apply"]).valid).toBe(false);
});

test("uses only exact observed commands for bash allow evidence", () => {
  const observed = { ...completed("command", "git status *", "once"), command: "git status --short" };
  expect(validateCandidate(candidate("bash", "git status --short", "allow", ["command"]), [observed], ["bash"]).valid).toBe(true);
  expect(validateCandidate(candidate("bash", "git status *", "allow", ["command"]), [observed], ["bash"]).valid).toBe(false);
  const noCommand = completed("no-command", "git status --short", "once");
  delete noCommand.command;
  expect(validateCandidate(candidate("bash", "git status --short", "allow", ["no-command"]), [noCommand], ["bash"]).valid).toBe(false);
  expect(validateCandidate(candidate("bash", "git status --short", "allow", ["resource"]), [completed("resource", "git status --short", "once", "edit")], ["bash"]).valid).toBe(false);
});

test("requires exact observed bash allow commands and rejects shell indirection", () => {
  const records = [completed("one", "git status", "once")];
  expect(validateCandidate(candidate("bash", "git status", "allow"), records, ["bash"]).valid).toBe(true);
  for (const pattern of ["git *", "git ?", "git status && rm -rf /", "cmd &", "(cmd)", "outer (inner)", "$(id)", "git status | cat", "git status > out", "bash -c x", "sudo git status", "env FOO=x git status", "source x", ". x", "command git status", "doas git status", "exec git status", "xargs git status", "git\nstatus"]) {
    expect(validateCandidate(candidate("bash", pattern, "allow"), records, ["bash"]).valid).toBe(false);
  }
});

test("allows exact bash deny wildcards and reports matching nonselected evidence", () => {
  const result = validateCandidate(candidate("bash", "git push *", "deny", ["one"]), [
    completed("one", "git push origin", "reject"), completed("two", "git push main", "reject"),
  ], ["bash"]);
  expect(result.valid).toBe(true);
  expect(result.matchingEvidenceIds).toEqual(["one", "two"]);
  expect(result.warnings.join(" ")).toContain("two");
});

test("blocks retained opposite evidence and permits same-direction evidence", () => {
  expect(validateCandidate(candidate("edit", "src/*.ts", "deny", ["one"]), [completed("one", "src/a.ts", "reject", "edit"), completed("two", "src/b.ts", "once", "edit")], ["edit"])).toMatchObject({ valid: false, conflictingEvidenceIds: ["two"] });
  expect(validateCandidate(candidate("edit", "src/*.ts", "allow", ["one"]), [completed("one", "src/a.ts", "once", "edit")], ["edit"]).valid).toBe(true);
});

test("converts flat JSONC policy and preserves comments and insertion order", () => {
  const before = `{
  // keep this comment
  "permission": { "edit": "ask", "read": "allow" }
}`;
  const patch = buildPolicyPatch(before, [candidate("edit", "src/*.ts", "allow")]);
  expect(JSON.parse(patch.after.replace(/\/\/.*$/gm, "")).permission.edit).toEqual({ "*": "ask", "src/*.ts": "allow" });
  expect(patch.after).toContain("keep this comment");
  expect(patch.after.indexOf('"edit"')).toBeLessThan(patch.after.indexOf('"read"'));
  expect(patch.changed).toBe(true);
  expect(patch.diff).toContain('"edit"');
  expect(patch.before).toBe(before);
  expect(patch.hash).toMatch(/^[a-f0-9]{64}$/);
});

test("appends narrow object rules after fallbacks and is idempotent", () => {
  const before = '{"permission":{"bash":{"*":"ask","git status *":"allow"}}}';
  const patch = buildPolicyPatch(before, [candidate("bash", "git status *", "allow")]);
  expect(patch.changed).toBe(false);
  expect(buildPolicyPatch(patch.after, [candidate("bash", "git status *", "allow")]).changed).toBe(false);
  const appended = buildPolicyPatch('{"permission":{"edit":{"*":"ask","src/**":"deny"}}}', [candidate("edit", "src/*.ts", "allow")]);
  expect(JSON.parse(appended.after).permission.edit).toEqual({ "*": "ask", "src/**": "deny", "src/*.ts": "allow" });
});

test("rejects conflicting actions in one batch", () => {
  expect(() => buildPolicyPatch("{}", [candidate("edit", "x", "allow"), candidate("edit", "x", "deny")])).toThrow("conflicting actions");
});

test("throws before patching malformed JSONC", () => {
  expect(() => buildPolicyPatch('{"permission":{"edit":"ask",', [candidate("edit", "src/*.ts", "allow")])).toThrow("parse errors");
});

test("warns when a broader appended candidate supersedes an earlier narrow rule", () => {
  const broader = buildPolicyPatch('{"permission":{"bash":{"git status":"deny"}}}', [candidate("bash", "git *", "allow")]);
  expect(broader.warnings.join(" ")).toContain("supersedes");
  const narrower = buildPolicyPatch('{"permission":{"bash":{"git *":"deny"}}}', [candidate("bash", "git status", "allow")]);
  expect(narrower.warnings).toEqual([]);
});
