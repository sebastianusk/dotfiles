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
- Verify after changing — run tests, build, or lint
- Prefer targeted edits over rewriting entire files
- Break complex tasks into small, verifiable steps
- When stuck, experiment (add logging, run code) rather than guess
- Use TDD for application code features and bug fixes only. For configuration, skill, agent, prompt, and other workflow-only changes, implement directly, run targeted validation, and ask the user to test the changed behavior manually.

## OpenCode workflow
- Use the native Plan agent for read-only analysis and planning
- Use native Task/subagents for independent work that can be parallelized
- Use native todos to track active session work
- Use `@brain` references for Obsidian tasks
