---
name: jira
description: Jira Cloud ticket management — create tickets on the team board, list your tickets, view ticket details. Use when the user says "create a jira ticket", "get my tickets", "show jira <KEY>", "jira detail <KEY>", or similar.
---

# jira — Jira Cloud Ticket Manager

## What I do

- Create tickets on the team board (project `DX`, issue type `Story` by default)
- List tickets assigned to the current user
- Show full detail of a ticket (fields, description, comments)
- Convenience: open in browser, add a comment, transition state, delete

## When to use me

Use this skill when the user says things like:
- "create a jira ticket", "create a ticket for ..."
- "get my tickets", "what's on my plate", "my jira tickets"
- "show jira ENG-123", "jira detail ENG-123", "what's the status of ..."
- "comment on ENG-123", "move ENG-123 to in progress", "delete ENG-123"

## Config

## Required env vars

- `ATLASSIAN_DOMAIN` — e.g. `<you>.atlassian.net`
- `ATLASSIAN_EMAIL` — your Atlassian account email
- `ATLASSIAN_API_TOKEN` — Cloud API token

Auth scheme: HTTP Basic, header `Authorization: Basic base64($ATLASSIAN_EMAIL:$ATLASSIAN_API_TOKEN)`.

The script guards at runtime — if any var is missing it prints the exact unset name and exits 1.

## Options

| Setting | Default | Override |
|---------|---------|----------|
| Project key | `DX` | `--project <KEY>` |
| Issue type | `Story` | `--type <Name>` |
| Assignee | currentUser (`self`) | `--no-assign` or `--assignee <accountId>` |
| Labels | `["dxt", "DXT"]` | (hardcoded — needed for team-board visibility) |

## Dependencies

- `curl` (system)
- `jq` (in Brewfile)

## Commands

All commands run via `./scripts/jira.sh <subcommand> [opts]` (paths relative to this skill dir).

### `auth-test`
Verify credentials. Caches your account info to `~/.cache/jira/myself.json` (used for self-assign).
```bash
./scripts/jira.sh auth-test
```

### `create`
Create a ticket. Default project `DX`, type `Story`, assignee = self.
```bash
./scripts/jira.sh create --summary "Title"
./scripts/jira.sh create --summary "Title" --desc "Longer description" --type Bug --project ENG --no-assign
```
Prints the new `<KEY>` and its browse URL.

### `mine`
List tickets assigned to you across all projects (default), active only (excludes Done). The ticket key prefix shows the project (e.g. `DX-1234`, `ENG-456`).
```bash
./scripts/jira.sh mine
./scripts/jira.sh mine --all
./scripts/jira.sh mine --project DX    # restrict to a single project
```

### `detail`
Show full detail of a ticket (summary, status, type, priority, assignee, reporter, dates, labels, components, description, comments).
```bash
./scripts/jira.sh detail ENG-123
./scripts/jira.sh detail ENG-123 --comments
```

### `open`
Open the ticket in the browser (macOS `open`).
```bash
./scripts/jira.sh open ENG-123
```

### `comment`
Add a comment to a ticket.
```bash
./scripts/jira.sh comment ENG-123 "Your comment text"
```

### `transition`
Transition a ticket to a new state. State name matches case-insensitively, partial match allowed (e.g. "progress" matches "In Progress").
```bash
./scripts/jira.sh transition ENG-123 "In Progress"
```

### `delete`
Delete a ticket. Requires `--force` to prevent accidents.
```bash
./scripts/jira.sh delete ENG-123 --force
```

### Help
```bash
./scripts/jira.sh --help
```

## Notes

- The script is self-contained bash — no asset files, only env + `~/.cache/jira/`.
- For endpoint/JQL/ADF details see [references/api-reference.md](references/api-reference.md).
- Always run `auth-test` first if credentials or domain may have changed.