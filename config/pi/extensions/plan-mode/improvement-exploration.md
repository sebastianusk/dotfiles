# Plan Mode Exploration Coverage

Status: review notes only. Do not implement changes from this document without discussing them first.

Scope: how plan mode should integrate the explorer subagent, a proposed docs subagent, a future web subagent, context-mode, and the docs-lookup skill. Separated from `improvement.md` (codegen/safety findings) to keep concerns distinct.

See also:
- `improvement.md` — items 2, 3, and 8 are the safety/parser findings most related to this document.
- `config/pi/extensions/subagent/index.ts` — the subagent tool implementation.
- `config/pi/agents/explorer.md` — the existing explorer agent.
- `config/pi/skills/docs-lookup/SKILL.md` — the docs-lookup skill.

## Exploration domains

| # | Domain | What it answers | Vehicle | Plan-mode allows? |
|---|---|---|---|---|
| 1 | Local code | structure, call sites, patterns, where things live | `subagent(explorer)` — `tools: read, grep, find, ls` | yes (agent toolset verified read-only) |
| 2 | Library/API docs | "what's the correct API for X? what does Y option do?" | `docs-lookup` skill + read-only ctx tools, inline or via a `docs` subagent | yes (read-only ctx tools only) |
| 3 | Web / strategy / current best practices | design tradeoffs, blog posts, "how do other teams solve Z" | future `researcher` subagent — pending a web-search tool that does not exist yet | deferred until web-search exists |
| 4 | Prior art / examples | gist/repo/Stack Overflow references for a pattern | fold into docs-lookup; `ctx_fetch_and_index` on known URLs | yes |
| 5 | Dependency / package graph | what's installed, versions, deprecations, audit, tree | deferred — see "Probe (domains 5–6)" below | TBD |
| 6 | Git / project history | who changed what and why, blame, PR context | deferred — see "Probe (domains 5–6)" below | TBD |
| 7 | Runtime / live state probes | run tests, hit dev API, inspect logs | execution phase only — not planning | no |

## Coordination model

- **Subagent** = isolation for *noisy* exploration (many tool calls, large intermediate content). Per agent, frontmatter `tools:` is the hard boundary enforced by the child process's `--tools` allowlist.
- **Skill** = *instructions only*. A subagent uses a skill only when the skill's referenced tools appear in that subagent's `tools:` allowlist. Otherwise the skill text loads but stays unexecutable.
- **context-mode** = tool provider + context saver. Read-only `ctx_search`/`ctx_fetch_and_index`/`ctx_index`/`ctx_stats` are cheap enough to use inline; `ctx_execute`/`ctx_execute_file`/`ctx_batch_execute` are the arbitrary-code hole plan mode must block; `ctx_purge` is destructive and must be blocked.

## Code subagent: explorer (exists)

- Status: shipping at `config/pi/agents/explorer.md`, `tools: read, grep, find, ls`.
- Safety: the child's `--tools` allowlist excludes built-in write tools and every ctx tool. Context-mode loads inside the child but its tools are inactive. Explorer cannot run arbitrary code.
- Plan-mode integration: allow `subagent` only when the chosen agent's `tools:` set is read-only (see "agent-argument guard" below). Explorer qualifies.
- Remains code-only. Do not widen its allowlist to include ctx tools; handle docs inline in the main planning session.

## Docs subagent: docs (recommended, optional)

- A dedicated `config/pi/agents/docs.md` with `tools: ctx_fetch_and_index, ctx_search, ctx_index, ctx_stats` and a body that follows the `docs-lookup` skill method (Context7 API, convention-based URL construction, fallback to codebase grep).
- Worth it when you want parallelism (explorer + docs run concurrently while the planner waits) or chatter isolation (docs verification is many ctx calls). Not worth it for one or two inline `ctx_search` calls.
- Constraint: `ctx_fetch_and_index` and `ctx_search` hit context-mode's single shared FTS5 database, so *parallel docs subagents* contend for the DB lock. One docs subagent at a time is fine. Explorer + docs in parallel is fine because explorer never touches FTS5.
- Plan-mode integration: allowed only if the agent's `tools:` set is a subset of the read-only ctx allowlist (`ctx_search`, `ctx_fetch_and_index`, `ctx_index`, `ctx_stats`). `ctx_execute*` and `ctx_purge` are excluded.

## Web subagent: researcher (deferred until web-search exists)

- A future `config/pi/agents/researcher.md` for domains 3 and 4, scoped to web/strategy + prior-art via a web-search tool plus `ctx_fetch_and_index` for result pages and `ctx_search` over indexed content.
- Blocking dependency: there is no web-search tool today. The `brave-search` reference at `index.ts:214` is stale — that skill was never created. researcher cannot exist until a web-search capability is added, either an MCP web-search server registered via context-mode's MCP bridge (Brave/Tavily/Serper) or a small extension wrapping a search API.
- Same parallelism/isolation rationale as docs; same FTS5 DB lock caveat.
- Plan-mode integration: allowed only if the agent's `tools:` set is read-only (web-search tool plus the read-only ctx allowlist); `ctx_execute*` and `ctx_purge` excluded.

## Footgun: skills load but do not execute in subagents

Confirmed from `subagent/index.ts:294-327`: a subagent child runs as `pi --mode json -p --no-session --tools <frontmatter tools> --append-system-prompt <agent.md body>`. It does not pass `--no-skills` or `--no-extensions`, so:

- All skills load into the child, including `docs-lookup` and context-mode's own skills. The skill text is present in the system prompt.
- All extensions load, including context-mode which registers `ctx_*` tools.
- The `--tools` allowlist is a hard allowlist across built-in, extension, and custom tools, so any ctx tool outside the agent's frontmatter `tools:` is registered-but-inactive.

Consequence: an agent whose frontmatter `tools:` excludes ctx tools, but whose system-prompt body (or loaded skills) instructs the model to call those tools, produces silent failures — the model attempts `ctx_fetch_and_index`, gets "tool not available", and burns tokens retrying. The skill system has no notion of "only load skills whose referenced tools are active."

Implication: doc/web subagents must either (a) include the needed ctx tools in their `tools:` allowlist, or (b) be authored to never mention ctx tools in their instructions. Option (a) is the only way to make docs-lookup actually usable from a subagent today.

## plan-mode must inspect the `agent` argument, not just allowlist the tool name

`subagent` is a meta-tool: its safety depends on its arguments. A parent session that allowlists `subagent` by tool name alone gives the model a path to spawn any agent, including a hypothetical `executor` with `tools: bash, edit, write`. The parent does not re-check read-only; the child's restrictions come entirely from the agent's frontmatter `tools:`.

So plan mode needs a `tool_call` guard that inspects `event.input.agent` / `event.input.tasks[].agent` / `event.input.chain[].agent`, resolves each against `discoverAgents(ctx.cwd, ...)`, and blocks any agent whose `tools:` set is not read-only. Prefer verifying the actual toolset from the agent registry over trusting a self-declared `readOnly: true` frontmatter flag. This is the same class of problem as `improvement.md` item 2 (tools whose effect depends on arguments) and finding #8's completion-marker trust.

## Probe (domains 5–6) — deferred

Dependency graph and git history (domains 5–6) need a read-only *command* channel that is neither arbitrary `bash` nor arbitrary `ctx_execute`. Shape and placement are deferred pending separate discussion. Not part of this code/web section.

## Current decision

Do not implement these changes yet. Discuss item by item first.