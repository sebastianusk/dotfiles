# Plan Tracker: Architecture & Extension Split

Status: review notes only. Do not implement changes from this document without discussing them first.

Scope: splitting plan-mode into two extensions and simplifying its lifecycle. Consolidates the preserved findings from the original review into the architecture they now belong to.

See also:
- `improvement-exploration.md` — exploration coverage (subagent/skill/context-mode integration, agent-argument guard).

## Core idea: plan-mode stops caring about execution

Plan-mode's job is to **write down** a plan, not to **execute** it. Two states only:

- **Planning** — read-only, produce a `Plan:` section, refine on re-entry.
- **Idle** — full tools, whatever the user wants (including executing the plan as a normal chat).

No execution mode. No `[DONE:n]`. No progress widget. No "Execute / Stay / Refine" dialog. The user drives the workflow: run `/plan` to toggle, work the plan in normal mode, re-run `/plan` to refine.

## Two extensions

| `plan-mode` (slim) | `plan-tracker` (the main thing) |
|---|---|
| `/plan` toggle | `.pi/plans/<name>.md` registry + auto-index |
| Read-only tool enforcement | Session→plan attachment pointer |
| Bash safety | Parser: extracts `Plan:` sections → writes file |
| agent-argument guard (exploration doc) | Completion: re-read file on `turn_end`, count checkboxes |
| Planning system-prompt injection | Footer `📋 X/Y` derived from checkbox count |
| Emits `plan:planning` / `plan:idle` | Commands: `/plans`, `/plan:attach`, `/plan:new`, `/todos` |

### Orthogonality

- plan-tracker works **without** plan-mode: track plans during normal chat (if a `Plan:` section appears and a plan is attached, update it).
- plan-mode works **without** plan-tracker: bare read-only toggle, no file.
- Composed: full experience.

### Capture ownership

plan-tracker owns capture. It listens for `plan:planning` (emitted by plan-mode) and gates `Plan:` extraction on that event or on an existing attachment. plan-mode never touches files.

## Event protocol

Tiny — two events, one direction each:

```ts
plan-mode emits:   plan:planning → plan-tracker: gate capture on next agent_end
                   plan:idle     → plan-tracker: stop gating capture
plan-tracker emits: plan:attached   → (informational; plan-mode may refine its prompt)
                   plan:completed  → (informational; plan-mode may note in a notify)
```

Real cost: two extensions must version together; an event bug desyncs them. Worth it for the separation.

## Plan-mode lifecycle (simplified)

```
/plan (enter):
  enforce read-only toolset + bash safety
  inject planning system prompt:
    "Produce a `Plan:` section with numbered steps."
  if plan-tracker says a plan is attached, mention the existing file
  emit plan:planning

  user discusses, model explores (read-only), produces/refines Plan: section
  plan-tracker captures → writes/updates .pi/plans/<name>.md

/plan (exit):
  restore full tools
  notify: "Plan saved to <path>. Re-run /plan to refine, or proceed."
  emit plan:idle
```

No execution state. No dialog. No widget.

## plan-tracker responsibilities

### Plan files

```
.pi/plans/
├── auth-refactor.md
├── migrate-config.md
└── README.md   ← auto-index, lists plans with status
```

- Repo-local. One plan per file. No single-file cross-session contention.
- Findability: `ls .pi/plans/` shows the backlog; `cat .pi/plans/README.md` shows plans with status.
- Commit or gitignore is the user's per-repo choice.
- No repo pollution beyond one `.pi/plans/` dir inside `.pi/`.

### Attachment pointer

Session→plan pointer = one session custom entry:

```ts
pi.appendEntry("plan-tracker-attachment", { planName })
```

- Branch-awareness is minor here: worst case a wrong plan attached after `/tree` — re-attach with `/plan:attach <name>`. Don't pay for branch-keyed pointers.
- fork/clone: copy the pointer (the new session inherits the plan). `/new`: no pointer; created on first plan capture.
- `/resume`: re-reads the pointer from the active branch.

### Plan file frontmatter

```yaml
---
status: planning | complete
updated: <iso timestamp>
---
```

- `status` is per-plan (not per-session) so any session reading it knows the lifecycle state.
- The attachment is per-session; the status is per-plan.

### Capture flow

```
plan:planning emitted
  │
  ▼
agent_end → assistant message has "Plan:" section?
  │  yes
  ▼
extractTodoItems() → list of steps (parser fix — see preserved findings)
  │
  ▼
plan attached?
  ├─ yes → update existing file (replace step list, preserve completed checkboxes)
  └─ no  → create new file from a name (ask user, or derive), attach, update index
  │
  ▼
emit plan:attached (if newly created)
```

### Completion tracking

No `[DONE:n]`. During normal mode (after plan exit), the model uses `edit` to check boxes:

```md
- [ ] Read auth module
- [x] Inspect router
- [ ] Write migration
```

plan-tracker re-reads the attached file on `turn_end` (or watches it) and updates the footer count `📋 1/3`. No parser for completion markers. No magic strings.

### Footer

- `📋 X/Y` whenever a plan is attached (planning or not).
- `⏸ plan` during planning phase (optional; plan-mode could set this).
- No multi-line widget. No hanging display.

### Commands

- `/plans` — list repo plans from `.pi/plans/`, select to attach.
- `/plan:new <name>` — create empty plan, attach.
- `/plan:attach <name>` — attach an existing plan.
- `/todos` — open the attached plan in nvim (`!nvim <path>` or print the path).

## Preserved findings (detail)

These findings survive the redesign and need implementation. Each is tagged with its owning extension.

### P1. Plan extraction parser (plan-tracker)

**Priority: high**

Current parser in `utils.ts:131-145`:

- Finds the first `Plan:` occurrence anywhere in the assistant response.
- Parses every numbered item until the end of the response.
- Does not stop at the next Markdown heading or section boundary.
- Does not ignore fenced code blocks or quoted examples.

This caused the plan generated during review to contain 20 items — it parsed a numbered example, the priority list, and the actual plan.

Related: the pattern at `utils.ts:135`:

```ts
/^\s*(\d+)[.)]\s+\*{0,2}([^*\n]+)/gm
```

truncates `1. **Inspect** the code` into just `Inspect`, losing `the code`.

Proposed fix:

- Support `Plan:`, `## Plan`, and `### Plan` headings.
- Parse the complete numbered line before removing Markdown formatting.
- Stop at the next heading.
- Ignore fenced code blocks and quoted examples.
- Preserve the original step text; use a separate shortened display value if necessary.
- Add parser tests for examples, nested sections, Markdown emphasis, code fences, and multiple Plan headings.

### P2. Read-only not enforced against custom tools (plan-mode)

**Priority: critical**

`index.ts:22-25, 91-94` only disables built-in `edit` and `write`. It preserves all other active tools via:

```ts
...activeToolNames.filter((name) => !PLAN_MODE_DISABLED_TOOLS.has(name))
```

This leaves mutation-capable custom tools active — notably `subagent` (can spawn a child Pi with full write access) and context-mode's `ctx_execute`/`ctx_execute_file`/`ctx_batch_execute` (arbitrary code).

Proposed fix:

- Use an explicit read-only tool allowlist during planning.
- Allow only `read`, `grep`, `find`, `ls`, and possibly `questionnaire`.
- Treat arbitrary custom tools as disabled unless explicitly declared read-only.
- Classify context-mode tools: allow `ctx_search`/`ctx_fetch_and_index`/`ctx_index`/`ctx_stats` (read-only); block `ctx_execute*` and `ctx_purge` (arbitrary code / destructive).
- Add a `tool_call` guard that rejects tools outside the planning allowlist.
- Inspect the `agent` argument of `subagent` calls and block agents whose `tools:` set is not read-only (see `improvement-exploration.md` "agent-argument guard").

The status text should not imply that disabling only built-in write tools guarantees read-only behavior.

### P3. Bash safety is bypassable (plan-mode)

**Priority: critical**

`utils.ts:7-100` uses safe-prefix + destructive-substring regexes. Not a reliable shell boundary.

Bypass examples classified as safe:

```text
cat README.md | python3 -c 'open("out","w").write("x")'
curl -X POST https://example.test/api
git diff --output=out
```

Other risky capabilities: `find -exec`/`-execdir`, `awk system()`, command substitution in `cat`/`echo`/`printf`, pipelines invoking interpreters, network-mutating `curl`, file-output options on read-only commands, execution-capable `sed` options.

Proposed fix:

Prefer removing arbitrary bash from plan mode — built-in read/search tools + explorer subagent cover most exploration. If bash must remain:

- Parse shell syntax instead of regexes.
- Reject pipes, command separators, redirects, command substitution, backticks, newlines, shell interpreters, and execution options.
- Permit only a small set of exact commands and read-only arguments.
- Prefer conservative false positives over possible writes.
- Add adversarial bypass tests.

Note: this overlaps with the "Probe (domains 5–6)" discussion in `improvement-exploration.md` — read-only command introspection (dep graph, git history) needs a channel that is neither arbitrary bash nor `ctx_execute`.

### P4. Tool restoration drops tools (plan-mode)

**Priority: medium**

`index.ts:96-114` stores and restores the entire active-tool snapshot.

Problems:

- The fallback normal set omits `grep`, `find`, and `ls`.
- Tools added by another extension while plan mode is active can be lost when restoring the snapshot.
- A stale persisted snapshot can contain unavailable tools.

Proposed fix:

Track only the tools changed by plan-mode:

- Remove tools added by plan-mode when leaving planning mode.
- Restore tools disabled by plan-mode.
- Preserve unrelated active-tool changes.
- Validate tool names against `pi.getAllTools()`.

### P5. `--plan` precedence across session replacement (plan-mode)

**Priority: low**

`index.ts:341-346` checks the CLI flag on every `session_start`, including `/new`, `/resume`, and `/fork`, which may unexpectedly re-enable planning in replacement sessions.

Proposed fix:

Define precedence between CLI flags and persisted state. Consider applying `--plan` only to the initial startup session.

### P6. Non-TUI behavior (plan-tracker)

**Priority: low**

No longer involves a dialog or widget (those are eliminated), but plan-tracker still needs to decide:

- Whether to capture `Plan:` sections in print/JSON mode (no `ctx.hasUI` gate needed since there's no dialog).
- Whether to write plan files in non-interactive mode or just output the plan as text.

Simpler than the original finding — no `agent_end` dialog to worry about. plan-tracker can capture in any mode since file I/O doesn't require UI.

## Eliminated findings

| Original finding | Why eliminated |
|---|---|
| #4 branch-awareness for execution state | No execution state; only attachment pointer (minor, re-attach manually) |
| #5 state not rebuilt on session_tree | Plan state lives in the file, not in-memory; attachment pointer re-read on session_start |
| #6 stale execution context | No execution context exists |
| #7 agent_end dialog race | No dialog |
| #8 [DONE:n] markers | Model edits checkboxes via `edit` |
| #10 persistence bloat | Only the attachment pointer; plan state lives in one file |

## Open decisions

1. **Naming.** `plan-tracker` vs `plan-file` vs `plans`. Bikeshed; pick before implementation.
2. **Capture outside planning.** Should plan-tracker capture `Plan:` sections in normal mode (when a plan is already attached but plan-mode is off)? Currently proposed: yes, if attached. Confirm.
3. **Footer count outside planning.** Keep `📋 X/Y` whenever a plan is attached, including during normal execution. Confirmed desired.
4. **Re-enter behaviour.** When re-entering plan-mode with an attached plan, the planning system prompt mentions the existing file: "an existing plan is attached at `<path>`; revise it, don't duplicate." Confirmed desired.
5. **Exit is explicit toggle.** The model doesn't auto-exit on a non-plan prompt. `/plan` toggles. Confirmed.
6. **Migration.** No existing plan files to migrate from. Clean cut — remove the old todo/widget/`[DONE:n]` logic from plan-mode when plan-tracker lands.
7. **Probe (domains 5–6).** Deferred — see `improvement-exploration.md`. Read-only command introspection for dep graph and git history needs a channel that is neither arbitrary bash nor `ctx_execute`.

## Proposed implementation order

1. Build `plan-tracker` with plan-file CRUD, attachment pointer, and the parser fix (P1).
2. Build the slim `plan-mode` with read-only enforcement (P2), bash safety (P3), tool transitions (P4), and `--plan` precedence (P5).
3. Wire the event protocol (`plan:planning` / `plan:idle`).
4. Remove old todo/widget/`[DONE:n]` logic from plan-mode.
5. Add tests: parser (P1), bash bypasses (P3), tool transitions (P4), non-TUI capture (P6).
6. Integration tests: reload, resume, fork, tree navigation, compaction, queued messages, custom tools.

## Current decision

Do not implement these changes yet. Discuss item by item first.