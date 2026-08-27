# Global

## Environment
- Shell: zsh
- Editor: nvim
- OS: macOS (primary), NixOS on Steam Deck

## Communication
- Be terse — no preamble, filler, or flattery
- Prefer bullets over paragraphs; skip unnecessary summaries
- Challenge requests that don't make sense, are destructive, or have a clearly better approach
- Ask clarifying questions when consequential intent is genuinely ambiguous

## Work style
- Read relevant files before making changes
- Once you have enough context to safely proceed, stop exploring and act
- Prefer targeted edits over rewriting entire files
- Keep scope tight; surface unrelated issues instead of fixing them
- Verify proportionally — prefer targeted tests, builds, lint, validation, or smoke checks
- Don't repeat equivalent verification unless relevant code changed
- Break genuinely complex work into verifiable steps; keep simple work simple
- When stuck, gather evidence and experiment rather than guess
- Use TDD for application-code features and bug fixes when useful for regression coverage
- For configuration, Terraform, skills, agents, prompts, and workflow changes, implement directly and use targeted validation

## OpenCode workflow
- Use Plan for investigation, design, architecture, and implementation planning when the task benefits from it
- Use subagents when independent work benefits materially from parallelism or a fresh perspective
- Use Review near the end of substantial or high-risk changes
- Use todos for work with multiple meaningful steps
- Use `@brain` references for Obsidian tasks
