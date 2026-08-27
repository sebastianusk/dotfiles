# Global

## Shell & editor
- Shell: zsh
- Editor: nvim

## OS
- macOS (primary), NixOS on Steam Deck

## Communication
- Be terse — no preamble, no filler, no flattery
- Bullet points over paragraphs; skip summaries
- Challenge me if the task doesn't make sense, seems destructive, or has a clearly better approach
- Ask clarifying questions when the goal is ambiguous — don't guess

## Work style
- Read relevant files before making changes
- Once you have enough context to safely make the change, stop exploring and implement
- Prefer targeted edits over rewriting entire files
- Keep scope tight; don't refactor or fix unrelated issues
- Verify proportionally after changing — prefer targeted tests, builds, lint, validation, or smoke checks
- Don't repeat equivalent verification unless relevant code changed
- Break genuinely complex tasks into small, verifiable steps; don't add process to simple tasks
- When stuck, experiment and gather evidence rather than guess
- Use TDD for application code features and bug fixes only. For configuration, skill, agent, prompt, and other workflow-only changes, implement directly and run targeted validation

## OpenCode workflow
- Use native Plan mode for design, architecture, investigation, and implementation planning when the task benefits from planning
- Use native Task/subagents when independent work materially benefits from parallelism or an independent perspective
- Use the Review subagent near the end of substantial or high-risk changes
- Use native todos for tasks with multiple meaningful steps
- Use `@brain` references for Obsidian tasks
