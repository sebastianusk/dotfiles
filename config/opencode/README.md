# OpenCode Configuration

Native-first OpenCode configuration with Plan/Build agents, selected shared
skills, and a small set of pinned plugins.

## Workflow

- **Plan**: read-only analysis and planning. It can ask questions and dispatch
  `explore` and `general`, but cannot edit files or run bash.
- **Build**: implementation with targeted bash approvals. Git commits and pushes
  are always denied.
- **Subagents**: use OpenCode's native Task tool. Child-session navigation uses
  the default TUI bindings.
- **Plans and work tracking**: use Superpowers for durable specs/plans and
  OpenCode's native todos for the current session.

## Agents

### Plan (`openai/gpt-5.6-sol`)

- Read/search/web access, questions, skills, and the `@explore` / `@general`
  subagents
- Cannot edit files or run shell commands
- High reasoning effort for planning and architecture decisions

### Build (`openai/gpt-5.6-terra`)

- Read/edit access and the `@explore` / `@general` subagents
- Read-only shell commands auto-allowed; other commands require approval
- Git commit and push always denied
- Medium reasoning effort for implementation

### Explore and General (`openai/gpt-5.6-luna`)

- **Explore**: fast read-only codebase investigation
- **General**: multi-step research and independent work

## Permission Notes

- Agent bash blocks are merged with (appended after) the global rules, so agent
  allows override global asks, but trailing global guards still apply to any
  pattern the agent does not re-allow.
- `* > *` / `* >> *` require approval globally: shell redirects would otherwise
  bypass write permissions through allowlisted read-only commands.
- The `general` subagent intentionally has no permission block and inherits the
  full global policy; `reviewer` denies bash outright.

## Skills and Brain Vault

OpenCode loads skills from `~/dotfiles/config/opencode/skills` and
brain-vault skills at `~/Documents/brain/agent/skills`.

- `dk`, `jira`, and `confluence` retain their existing scripts and CLI/API
  dependencies.
- `docs-lookup` uses the configured Context7 MCP for library and tool docs.
- Tavily is provided by the Tavily MCP.
- `@brain` exposes `~/Documents/brain` for explicit task-note references; there
  is no hidden task-session attachment plugin.
- Brain-vault prompt commands are individually linked into
  `~/dotfiles/config/commands`; add other global commands there.

## Files

| File | Purpose |
| --- | --- |
| `opencode.json` | Agents, models, permissions, skills, plugins, references, and MCPs |
| `tui.json` | TUI theme and keybindings |
| `AGENTS.md` | Global OpenCode workflow instructions |
| `skills/docs-lookup/SKILL.md` | Context7-first current documentation workflow |
| `../commands/` | Global slash commands; selected files link to brain-vault prompts |
| `hermes-memory.jsonc` | Local, approval-gated persistent-memory configuration |
| `approval-review.jsonc` | Local permission-decision recording and promotion configuration |
| `vibeguard.config.json` | Sensitive-value redaction patterns |
| `opencode-notifier.json` | macOS notification configuration |
| `sync.sh` | Safely symlinks this configuration into `~/.config/opencode/` |

## Plugins

| Plugin | Purpose |
| --- | --- |
| `@mohak34/opencode-notifier` | macOS notifications and tmux focus restoration |
| `extensions/hermes-memory` | Local, approval-gated memory proposals across sessions |
| `extensions/approval-review` | Records permission decisions; `/approval-review` promotes confirmed allow/deny rules |
| `opencode-vibeguard` | Configured sensitive-value redaction |
| `context-mode` | Large-output offloading, FTS search, and compaction continuity |

Plugins are version-pinned. `opencode-gemini-auth` is intentionally omitted:
its third-party OAuth flow has an account-policy risk.

## Approval Review

`extensions/approval-review` records interactive permission decisions locally
and provides a manual `/approval-review` command that turns reviewed evidence
into global permission rules after explicit confirmation of the exact diff.

- Storage: `~/.local/share/opencode/approval-review/records/`, mode `0700`
  directories and `0600` files; session IDs are never persisted.
- Retention: records are pruned after 90 days.
- Redaction: values matching the effective Vibeguard config are redacted
  before persistence; redacted evidence is audit-only and never promotes
  rules. If Vibeguard config is missing or invalid, nothing is recorded.
- Promotion: allow candidates for `bash` must be exact observed commands —
  wildcards cannot safely cover shell chaining. Wildcard deny candidates and
  non-bash wildcards are supported. Custom permission gates are audit-only
  unless listed in `approval-review.jsonc`.
- Application: policy changes write through the `~/.config/opencode/opencode.json`
  symlink target atomically, preserving comments and rule order, and require
  restarting OpenCode to take effect.

## MCP Servers

| Server | Purpose |
| --- | --- |
| `context7` | Up-to-date library and API documentation |
| `tavily` | Web search, extraction, map, and crawl |

## Context Mode Trial

`context-mode` is installed as an OpenCode plugin, not an MCP server. Do not add
`mcp.context-mode`: combining both paths prevents `ctx_*` tools from registering.
After restarting OpenCode, verify it with `ctx doctor` and `ctx stats`.

## Sync and Restart

```bash
./sync.sh
```

The sync script does not overwrite existing regular files or directories in
`~/.config/opencode`; it reports them instead. Quit and restart OpenCode after
changing configuration, skills, agents, or plugins because they load at startup.
