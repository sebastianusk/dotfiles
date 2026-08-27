import { createHash } from "node:crypto";
import { modify, parse, applyEdits, type FormattingOptions, type ParseError } from "jsonc-parser";
import type { ApprovalRecord, RuleCandidate, ValidationResult } from "./types.js";
import { matches } from "./wildcard.js";

const APPLY_PERMISSION = "approval-review-apply";
const BUILT_INS = new Set(["bash", "edit", "write", "read", "list", "glob", "grep", "webfetch", "todoread", "todowrite", "task", "skill", "question", "lsp", "codesearch", "external_directory"]);
const SHELL_FORBIDDEN = /(?:&&|\|\||[|;&()<>`\n\r]|\$\(|\$\{|\b(?:sh|bash|eval|xargs|sudo|env|source|command|doas|exec)\b|(?:^|\s)\.(?=\s|$))/;

export type PolicyPatch = {
  before: string;
  after: string;
  hash: string;
  changed: boolean;
  diff: string;
  warnings: string[];
};

export function validateCandidate(candidate: RuleCandidate, records: ApprovalRecord[], promotablePermissions: string[]): ValidationResult {
  const base = { matchingEvidenceIds: [] as string[], conflictingEvidenceIds: [] as string[], warnings: [] as string[] };
  if (!candidate.pattern || candidate.pattern === "*") return { ...base, valid: false, reason: "Bare wildcard rules are not permitted." };
  if (!isPromotable(candidate.permission, promotablePermissions)) return { ...base, valid: false, reason: "This permission is audit-only." };
  if (candidate.permission === APPLY_PERMISSION) return { ...base, valid: false, reason: "Plugin apply confirmation permission is never promotable." };
  if (candidate.permission === "bash" && candidate.action === "allow" && (/[?*]/.test(candidate.pattern) || SHELL_FORBIDDEN.test(candidate.pattern))) {
    return { ...base, valid: false, reason: "Bash allow rules must be exact, non-shell command strings." };
  }

  const selected = records.filter((record) => candidate.evidenceIds.includes(record.id));
  if (selected.length !== candidate.evidenceIds.length) return { ...base, valid: false, reason: "Every evidence ID must identify a retained record." };
  if (selected.some((record) => record.reply === undefined || !record.repliedAt || record.disposition !== "unreviewed")) return { ...base, valid: false, reason: "Evidence must be completed and selected for review." };
  if (selected.some((record) => record.permission !== candidate.permission)) return { ...base, valid: false, reason: "Evidence must use the proposed permission." };
  if (selected.some((record) => record.redacted)) return { ...base, valid: false, reason: "Redacted evidence cannot create a rule." };
  if (candidate.permission === "bash" && candidate.action === "allow" && selected.some((record) => record.command === undefined || record.command !== candidate.pattern)) {
    return { ...base, valid: false, reason: "Bash allow evidence must contain the exact unredacted observed command." };
  }

  const direction = candidate.action === "allow" ? ["once", "always"] : ["reject"];
  const opposite = candidate.action === "allow" ? ["reject"] : ["once", "always"];
  const matching = records.filter((record) => record.permission === candidate.permission && observedValues(record, candidate).some((value) => matches(value, candidate.pattern)));
  const selectedMatching = matching.filter((record) => candidate.evidenceIds.includes(record.id));
  if (selectedMatching.length === 0) return { ...base, valid: false, reason: "Candidate must match selected evidence patterns." };
  const conflicts = matching.filter((record) => record.reply && opposite.includes(record.reply));
  const warnings = matching.filter((record) => !candidate.evidenceIds.includes(record.id) && record.reply && direction.includes(record.reply)).map((record) => `Non-selected matching evidence: ${record.id}.`);
  if (matching.some((record) => record.disposition !== "unreviewed")) warnings.push("Candidate matches existing superseded or applied evidence; no cleanup is proposed.");
  if (conflicts.length) return { valid: false, reason: "Candidate conflicts with opposite decisions.", matchingEvidenceIds: matching.map((record) => record.id), conflictingEvidenceIds: conflicts.map((record) => record.id), warnings };
  return { valid: true, matchingEvidenceIds: matching.map((record) => record.id), conflictingEvidenceIds: [], warnings };
}

export function buildPolicyPatch(configText: string, rules: Array<Pick<RuleCandidate, "permission" | "pattern" | "action">>): PolicyPatch {
  const parseErrors: ParseError[] = [];
  const parsed: unknown = parse(configText, parseErrors);
  if (parseErrors.length) throw new Error(`JSONC parse errors: ${parseErrors.length} error(s).`);
  if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) throw new Error("Policy config must be an object.");
  const root = parsed as Record<string, unknown>;
  if (root.permission !== undefined && (!root.permission || typeof root.permission !== "object" || Array.isArray(root.permission))) throw new Error("permission must be an object.");
  const seen = new Map<string, string>();
  for (const rule of rules) {
    const key = `${rule.permission}\0${rule.pattern}`;
    const prior = seen.get(key);
    if (prior && prior !== rule.action) throw new Error("conflicting actions for the same permission and pattern");
    seen.set(key, rule.action);
  }
  let after = configText;
  const permission = (root.permission ??= {}) as Record<string, unknown>;
  const warnings: string[] = [];
  for (const rule of rules) {
    const current = permission[rule.permission];
    if (typeof current === "string") {
      if (current === rule.action) {
        warnings.push(`Existing ${rule.permission} policy already covers ${rule.pattern}.`);
        continue;
      }
      const replacement = { "*": current, [rule.pattern]: rule.action };
      after = applyEdits(after, modify(after, ["permission", rule.permission], replacement, formatting())).trimEnd() + (after.endsWith("\n") ? "\n" : "");
      permission[rule.permission] = replacement;
    } else if (current && typeof current === "object" && !Array.isArray(current)) {
      const object = current as Record<string, unknown>;
      if (object[rule.pattern] === rule.action) {
        warnings.push(`Existing ${rule.permission} policy already covers ${rule.pattern}.`);
        continue;
      }
      if (object[rule.pattern] !== undefined && object[rule.pattern] !== rule.action) throw new Error("conflicting actions for the same permission and pattern");
      for (const [existingPattern, existingAction] of Object.entries(object)) {
        if (existingPattern !== rule.pattern && typeof existingAction === "string" && matches(existingPattern, rule.pattern)) {
          warnings.push(`Appended ${rule.permission} candidate ${rule.pattern} supersedes earlier rule ${existingPattern}.`);
        }
      }
      after = applyEdits(after, modify(after, ["permission", rule.permission, rule.pattern], rule.action, formatting()));
      object[rule.pattern] = rule.action;
    } else {
      after = applyEdits(after, modify(after, ["permission", rule.permission], { [rule.pattern]: rule.action }, formatting()));
      permission[rule.permission] = { [rule.pattern]: rule.action };
    }
  }
  const hash = createHash("sha256").update(after).digest("hex");
  return { before: configText, after, hash, changed: after !== configText, diff: lineDiff(configText, after), warnings };
}

function isPromotable(permission: string, allowlist: string[]): boolean { return permission !== APPLY_PERMISSION && (BUILT_INS.has(permission) || allowlist.includes(permission)); }
function observedValues(record: ApprovalRecord, candidate: RuleCandidate): string[] {
  return candidate.permission === "bash" && candidate.action === "allow" ? (record.command === undefined ? [] : [record.command]) : record.patterns;
}
function formatting(): { formattingOptions: FormattingOptions } { return { formattingOptions: { insertSpaces: true, tabSize: 2, eol: "\n" } }; }
function lineDiff(before: string, after: string): string { if (before === after) return ""; const oldLines = before.split("\n"); const newLines = after.split("\n"); return [...oldLines.filter((line, index) => line !== newLines[index]).map((line) => `- ${line}`), ...newLines.filter((line, index) => line !== oldLines[index]).map((line) => `+ ${line}`)].join("\n"); }
