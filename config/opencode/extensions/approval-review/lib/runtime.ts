import { createHash, randomUUID } from "node:crypto";
import { mkdir, readFile, realpath, rename, writeFile } from "node:fs/promises";
import { homedir } from "node:os";
import { dirname, join } from "node:path";
import { tool } from "@opencode-ai/plugin";
import { parse as parseJsonc, type ParseError } from "jsonc-parser";
import { normalizePermissionEvent } from "./events.js";
import { buildPolicyPatch, validateCandidate, type PolicyPatch } from "./policy.js";
import type { ApprovalRecord, RuleCandidate } from "./types.js";
import type { ApprovalReviewStore } from "./store.js";

export const APPLY_PERMISSION = "approval-review-apply";

const REDACTED_NOTICE = "Records containing [REDACTED] are audit-only and cannot support rules.";

export type ApprovalReviewDeps = {
  store: ApprovalReviewStore;
  configPath: string;
  promotablePermissions: string[];
};

export type CandidateInput = {
  permission: string;
  pattern: string;
  action: "allow" | "deny";
  evidenceIds: string[];
  explanation?: string;
};

function toCandidate(input: CandidateInput): RuleCandidate {
  return { ...input, explanation: input.explanation ?? "" };
}

async function writeAtomic(path: string, content: string): Promise<void> {
  const temporary = `${path}.${randomUUID()}.tmp`;
  await writeFile(temporary, content, { encoding: "utf8", mode: 0o600 });
  await rename(temporary, path);
}

function groupEvidence(records: ApprovalRecord[]) {
  const groups = new Map<string, {
    permission: string;
    examples: string[];
    command?: string;
    redacted: boolean;
    replies: Record<"once" | "always" | "reject", number>;
    ids: string[];
  }>();
  for (const record of records) {
    const example = record.patterns[0] ?? "";
    const key = `${record.permission}\u0000${record.command ?? example}`;
    let group = groups.get(key);
    if (!group) {
      group = {
        permission: record.permission,
        examples: [],
        ...(record.command === undefined ? {} : { command: record.command }),
        redacted: false,
        replies: { once: 0, always: 0, reject: 0 },
        ids: [],
      };
      groups.set(key, group);
    }
    if (!group.examples.includes(example)) group.examples.push(example);
    group.redacted ||= record.redacted;
    if (record.reply) group.replies[record.reply] += 1;
    group.ids.push(record.id);
  }
  return [...groups.values()];
}

function summarize(records: ApprovalRecord[]) {
  return {
    total: records.length,
    note: REDACTED_NOTICE,
    groups: groupEvidence(records),
  };
}

export function createEventHook(store: ApprovalReviewStore) {
  return async ({ event }: { event: unknown }): Promise<void> => {
    try {
      const normalized = normalizePermissionEvent(event);
      if (!normalized) return;
      if (normalized.kind === "asked") {
        if (normalized.input.permission === APPLY_PERMISSION) return;
        const result = await store.recordAsked(normalized.input);
        if (!result.written) console.error(`[approval-review] skipped record ${normalized.input.id}: ${result.reason}`);
        return;
      }
      await store.recordReplied(normalized.id, normalized.reply);
    } catch (error) {
      console.error("[approval-review]", error instanceof Error ? error.message : error);
    }
  };
}

export function createApprovalReviewTools(deps: ApprovalReviewDeps) {
  const candidateSchema = tool.schema.object({
    permission: tool.schema.string().min(1),
    pattern: tool.schema.string().min(1),
    action: tool.schema.enum(["allow", "deny"]),
    evidenceIds: tool.schema.array(tool.schema.string()).min(1),
    explanation: tool.schema.string().optional(),
  });

  async function readConfig(): Promise<string> {
    return readFile(deps.configPath, "utf8");
  }

  const listTool = tool({
    description: "Load grouped unreviewed OpenCode permission decisions. Run once at the start of /approval-review.",
    args: {},
    async execute() {
      await deps.store.prune();
      const records = await deps.store.beginReview();
      return JSON.stringify(summarize(records));
    },
  });

  const validateTool = tool({
    description: "Validate proposed allow/deny rules against retained evidence and the current global permission policy.",
    args: { candidates: tool.schema.array(candidateSchema).min(1) },
    async execute(args) {
      const records = await deps.store.listReviewable();
      const results = args.candidates.map((input) => ({
        candidate: input,
        validation: validateCandidate(toCandidate(input), records, deps.promotablePermissions),
      }));
      const validRules = results.filter((result) => result.validation.valid)
        .map((result) => ({ permission: result.candidate.permission, pattern: result.candidate.pattern, action: result.candidate.action }));
      let patch: PolicyPatch | undefined;
      if (validRules.length) {
        try {
          patch = buildPolicyPatch(await readConfig(), validRules);
        } catch (error) {
          return JSON.stringify({ results, error: error instanceof Error ? error.message : String(error) });
        }
      }
      return JSON.stringify({ results, patch });
    },
  });

  const dispositionTool = tool({
    description: "Mark reviewed evidence as dismissed or deferred. Deferred evidence becomes eligible again at the next review.",
    args: {
      ids: tool.schema.array(tool.schema.string()).min(1),
      disposition: tool.schema.enum(["dismissed", "deferred"]),
    },
    async execute(args) {
      await deps.store.setDisposition(args.ids, args.disposition);
      return JSON.stringify({ updated: args.ids.length, disposition: args.disposition });
    },
  });

  const applyTool = tool({
    description: "Apply previously validated rules to the global permission policy after explicit user confirmation of the exact diff.",
    args: { candidates: tool.schema.array(candidateSchema).min(1) },
    async execute(args, context) {
      const rules = args.candidates.map(toCandidate);
      const records = await deps.store.listReviewable();
      for (const candidate of rules) {
        const validation = validateCandidate(candidate, records, deps.promotablePermissions);
        if (!validation.valid) throw new Error(`Candidate ${candidate.permission} "${candidate.pattern}" is invalid: ${validation.reason}`);
      }

      const beforeText = await readConfig();
      const firstPass = buildPolicyPatch(beforeText, rules);

      await context.ask({
        permission: APPLY_PERMISSION,
        patterns: [firstPass.hash],
        always: [],
        metadata: { diff: firstPass.diff, rules },
      });

      const outcome = await deps.store.withLock(async (locked) => {
        const currentText = await readConfig();
        const patch = buildPolicyPatch(currentText, rules);
        if (patch.hash !== firstPass.hash) throw new Error("OpenCode config changed since review preview; rerun validation.");
        const errors: ParseError[] = [];
        parseJsonc(patch.after, errors);
        if (errors.length) throw new Error(`Generated config is invalid: ${errors.length} parse error(s).`);
        const resolvedPath = await realpath(deps.configPath);
        await mkdir(dirname(resolvedPath), { recursive: true, mode: 0o700 });
        await writeAtomic(resolvedPath, patch.after);
        const evidenceIds = [...new Set(rules.flatMap((rule) => rule.evidenceIds))];
        await locked.setDisposition(evidenceIds, "rule-applied", { ruleApplication: true });
        return { applied: rules.length, evidenceIds };
      });

      return `${JSON.stringify(outcome)}\nApplied successfully. Quit and restart OpenCode for new rules to take effect.`;
    },
  });

  return {
    approval_review_list: listTool,
    approval_review_validate: validateTool,
    approval_review_apply: applyTool,
    approval_review_disposition: dispositionTool,
  };
}

export function hashProject(directory: string): string {
  return createHash("sha256").update(directory).digest("hex").slice(0, 16);
}

export function resolveOpenCodeConfigPath(home = homedir()): string {
  return join(home, ".config", "opencode", "opencode.json");
}
