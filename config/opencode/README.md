# Oh My OpenAgent Configuration

Configuration for [oh-my-openagent](https://github.com/code-yeongyu/oh-my-openagent) plugin with cost-effective model selection.

## Philosophy

- **Daily driving**: Use `opencode-go` subscription models (included in subscription)
- **Deep review on demand**: Use expensive `opencode` models (Claude Opus) only when explicitly needed
- **Automatic resilience**: Fallback chains ensure work continues if primary models fail

## Agent Configuration

### Primary Agents (Tab-Cyclable in TUI)

Press **Tab** to cycle between these agents in the OpenCode TUI:

| Agent | Model | Cost | Usage |
|-------|-------|------|-------|
| **Sisyphus** | `opencode-go/kimi-k2.5` | FREE | Main orchestrator. Auto-activates with `/start-work`. Coordinates all subagents. |
| **Prometheus** | `opencode-go/glm-5.1` | FREE | Strategic planner. Interviews, scopes, creates work plans. Auto-activates during planning. |
| **Hephaestus** | `opencode-go/kimi-k2.5` | FREE | Interactive builder. Tab to this for direct coding, quick edits, debugging. |

**Note on Hephaestus**: This agent is optimized for GPT models. Using `kimi-k2.5` triggers a warning but works fine for interactive coding. The warning is advisory, not a blocker.

### Subagents (Dispatched Automatically or On-Demand)

These agents are called automatically by Sisyphus/Prometheus, or you can invoke them via `task()` or slash commands:

| Agent | Model | Cost | Usage |
|-------|-------|------|-------|
| **Librarian** | `opencode-go/minimax-m2.7` | FREE | Documentation researcher. Finds OSS examples, external docs. |
| **Explore** | `opencode-go/minimax-m2.5` | FREE | Codebase explorer. Searches for patterns, references, usages. |
| **Atlas** | `opencode-go/kimi-k2.5` | FREE | Plan executor. Distributes tasks to subagents during `/start-work`. |
| **Multimodal-looker** | `opencode-go/mimo-v2-omni` | FREE | Vision specialist. Analyzes images, screenshots, diagrams. |

### Expensive Subagents (Pay-Per-Use)

These use Claude Opus for deep reasoning. They're called automatically during planning or when you explicitly request deep review:

| Agent | Model | Cost | Usage |
|-------|-------|------|-------|
| **Oracle** | `opencode/claude-opus-4-6` (max) | PAID | Architecture consultant. Deep read-only analysis, debugging. Called during `/start-work` or on request. |
| **Metis** | `opencode/claude-opus-4-6` (max) | PAID | Plan reviewer. Catches gaps before plan execution. Auto-called during planning. |
| **Momus** | `opencode/claude-opus-4-6` (max) | PAID | Plan critic. Validates clarity and completeness. Called when you choose "High Accuracy Review". |

### The Workhorse: Sisyphus-junior

`Sisyphus-junior` doesn't have a fixed model — it selects based on the **category** of work. This is where 90% of your actual implementation happens during `/start-work`.

## Category Configuration

Categories control which model Sisyphus-junior uses for different types of work:

| Category | Model | Cost | When Used |
|----------|-------|------|-----------|
| `quick` | `opencode-go/minimax-m2.5` | FREE | Trivial tasks: typo fixes, single-file changes |
| `unspecified-low` | `opencode-go/kimi-k2.5` | FREE | General tasks with low effort |
| `unspecified-high` | `opencode-go/kimi-k2.5` | FREE | General tasks with high effort |
| `deep` | `opencode-go/kimi-k2.5` (with Opus fallback) | FREE → PAID | Autonomous problem-solving, thorough research. Escalates to Opus if needed. |
| `artistry` | `opencode-go/kimi-k2.5` | FREE | Creative/unconventional approaches |
| `writing` | `opencode-go/minimax-m2.7` | FREE | Documentation, prose, technical writing |
| `git` | `opencode-go/minimax-m2.5` | FREE | Git operations: commits, rebases, blame |
| `visual-engineering` | `opencode/gemini-3.1-pro` (high) | PAID | Frontend, UI/UX, design, animation. Gemini is best for visual tasks. |
| `ultrabrain` | `opencode/claude-opus-4-6` (max) | PAID | Deep logical reasoning, complex architecture. Use sparingly. |

## Cost Breakdown

### Typical Daily Workflow (95% FREE)

1. **Plan work with Prometheus** → FREE (`opencode-go/glm-5.1`)
2. **Metis auto-reviews plan** → PAID (brief Opus call, ~$0.05-0.20)
3. **Sisyphus-junior executes via categories** → FREE (minimax/kimi via subscription)
4. **Hephaestus for quick edits** → FREE (kimi via subscription)
5. **You choose "High Accuracy Review"** → PAID (Momus Opus call, ~$0.10-0.50)

### When You Pay

- **Oracle consultation**: When you explicitly ask for architectural review
- **Metis review**: Automatic during planning (brief, one-shot)
- **Momus review**: When you select "High Accuracy Review" option
- **Ultrabrain tasks**: When Sisyphus-junior classifies work as needing deep reasoning
- **Visual tasks**: When using `visual-engineering` category

## Resilience Features

### Fallback Models

Every agent has `fallback_models` configured:
- If `opencode-go` hits rate limits → falls back to `opencode/gpt-5.4`
- If Opus is unavailable → falls back to GPT-5.4

### Runtime Fallback

- **Enabled**: `true`
- **Retry on errors**: 400, 429, 503, 529
- **Max attempts**: 3
- **Notifications**: On (toast when fallback triggers)

### Concurrency Limits

| Provider | Limit | Reason |
|----------|-------|--------|
| `opencode-go` | 10 | Subscription = cheaper, can run more in parallel |
| `opencode` | 3 | Pay-per-use = limit concurrent expensive calls |
| `opencode-go/kimi-k2.5` | 8 | Main subscription workhorse |
| `opencode/claude-opus-4-6` | 2 | Expensive = strict limit |

## Key Commands

```bash
# Check model resolution
bunx oh-my-opencode doctor --verbose

# Test configuration
bunx oh-my-opencode doctor

# List available models
opencode models
```

## Files

- `oh-my-openagent.jsonc` - Main configuration (this setup)
- `opencode.json` - Core OpenCode settings and MCPs
- `tui.json` - TUI-specific settings
- `sync.sh` - Sync script for this directory

## Notes

- Restart OpenCode after editing `oh-my-openagent.jsonc`
- JSONC supports comments (`//` and `/* */`) and trailing commas
- Schema validation: https://raw.githubusercontent.com/code-yeongyu/oh-my-openagent/dev/assets/oh-my-opencode.schema.json
