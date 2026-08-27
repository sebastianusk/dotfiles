---
description: Review recorded OpenCode permission decisions and promote confirmed allow/deny rules.
---

Review recorded OpenCode permission decisions and turn confirmed patterns into global permission rules. Never edit `opencode.json` directly; only plugin tools may change policy.

## Workflow

1. Call `approval_review_list` exactly once at the start. If it returns no evidence, tell the user there is nothing to review and stop. Report any redacted evidence as audit-only — it cannot support rules.
2. Present the grouped evidence with explicit decision counts (`once`, `always`, `reject`) and concrete example commands/patterns. Do not invent rules that have no supporting examples.
3. For each evidence group, propose at most one candidate rule:
   - Allow candidates for `bash` must be exact observed commands (no `*`, no `?`, no shell operators or wrappers) and need an observed command as evidence.
   - Wildcard deny candidates are allowed subject to validation.
   - Custom permission gates are audit-only unless configured otherwise.
   - Describe each proposed wildcard's textual scope in plain language so the user can judge its breadth.
4. Call `approval_review_validate` on all proposed candidates before asking the user to select any. Present the resulting policy diff preview, warnings, and any conflicts. Do not offer candidates that failed validation except to explain why they failed.
5. Ask the user which validated candidates to apply. Only candidates explicitly selected in this review may be applied.
6. For selected candidates call `approval_review_apply`. The user must confirm the exact diff through the native prompt; a rejection means nothing changed.
7. After applying, ask whether each remaining unselected group should be dismissed (handled until new matching evidence appears) or deferred (returns at your next review). Record the choice with `approval_review_disposition`.
8. Remind the user that accepted changes require quitting and restarting OpenCode before they take effect.

## Safety rules

- Never call `approval_review_apply` without an explicit user selection made in this conversation.
- Never propose allow rules derived from redacted evidence, conflicting decisions, or non-selected-only evidence.
- Never remove, reorder, or clean up existing permission rules.
- Rejected requests are always eligible deny candidates with the same confirmation flow as allow rules.
