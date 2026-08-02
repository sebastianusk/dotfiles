---
description: Schedule a task for a date — set scheduled and optionally status: ready
argument-hint: "<task-name> [date]"
---
Read ~/.pi/agent/skills/tasks/SKILL.md and follow the /tasks-schedule workflow.
Find task "$1" in ~/Documents/brain/Tasks/*.md and schedule it.
Date: ${2:-today}. If status is todo or done, also set status: ready.
