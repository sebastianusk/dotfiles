---
description: Build agent for implementing code changes. Full edit access, restricted subagent spawning.
mode: primary
model: opencode-go/glm-5.3-flash
reasoningEffort: low
permission:
  edit: allow
  task:
    "*": deny
    explore: allow
    general: allow
  read: allow
  list: allow
  glob: allow
  grep: allow
  webfetch: allow
  todoread: allow
  todowrite: allow
  question: allow
  skill: allow
---

You are in build mode. Implement the requested changes following existing code conventions and security best practices. Verify with targeted tests/lint when possible.
