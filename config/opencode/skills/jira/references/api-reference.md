# Jira Cloud REST API Reference (v3)

Load-on-demand cheat-sheet for the endpoints, JQL, and Atlassian Document Format (ADF) used by `scripts/jira.sh`.

## Base URL

```
https://$ATLASSIAN_DOMAIN/rest/api/3
```

## Auth

HTTP Basic, header:
```
Authorization: Basic base64($ATLASSIAN_EMAIL:$ATLASSIAN_API_TOKEN)
Accept: application/json
Content-Type: application/json
```

A 401 means bad `ATLASSIAN_EMAIL` / `ATLASSIAN_API_TOKEN` combination. A 404 means a typo in the project or issue key. A 400 usually means JQL or body syntax.

## Endpoints used

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/myself` | Current user — accountId, displayName, emailAddress |
| POST | `/issue` | Create an issue |
| POST | `/search/jql` (body: `{jql,fields,maxResults}`) | JQL search — `/search` removed (410) |
| GET | `/issue/<KEY>?fields=...` | Issue detail |
| POST | `/issue/<KEY>/comment` | Add comment |
| GET | `/issue/<KEY>/transitions` | List available transitions |
| POST | `/issue/<KEY>/transitions` | Perform a transition |
| DELETE | `/issue/<KEY>?deleteSubtasks=true` | Delete an issue |

## Create body

```json
{
  "fields": {
    "project":      { "key": "DX" },
    "summary":      "Title",
    "description":  { "type":"doc","version":1,"content":[{"type":"paragraph","content":[{"type":"text","text":"body"}]}] },
    "issuetype":    { "name": "Story" },
    "labels":        ["dxt", "DXT"],
    "assignee":     { "accountId": "<from /myself>" }
  }
}
```

`assignee` is optional — omit it for `--no-assign`. Do not send `reporter`; the server sets it from auth. The `labels` array is hardcoded ("dxt","DXT") so tickets surface on the team board.

## JQL patterns

Current user's active tickets (all projects):
```
assignee = currentUser() AND statusCategory != Done
```

Scope to a specific project:
```
assignee = currentUser() AND project = DX AND statusCategory != Done
```

The `/rest/api/3/search/jql` endpoint accepts POST with body `{"jql":..., "fields":[...], "maxResults":100}`. The legacy `/rest/api/3/search` (and v2) returns 410 Gone. Response issues shape unchanged; no `total` field — use `isLast` for paging.

Include Done:
```
assignee = currentUser() AND project = DX
```

`statusCategory` values: `Done`, `Indeterminate` (in-progress), `To Do` (todo). Prefer `statusCategory != Done` over listing explicit status names — it survives workflow renames.

## Field-key matrix

| Concept | Field key | Example value |
|---------|-----------|---------------|
| Project | `project.key` | `"DX"` |
| Issue type | `issuetype.name` | `"Story"` / `"Bug"` / `"Task"` |
| Assignee | `assignee.accountId` | `"5f..."` |
| Reporter | `reporter.accountId` | `"5f..."` |
| Status | `status.name` | `"In Progress"` |
| Status category | `statusCategory.key` | `"indeterminate"` |
| Priority | `priority.name` | `"Medium"` |

## ADF (Atlassian Document Format)

Both `description` and comment `body` use ADF v1. The minimal structure used by this skill is one paragraph with one text node:

```json
{ "type":"doc","version":1,"content":[{"type":"paragraph","content":[{"type":"text","text":"..."}]}] }
```

Multi-paragraph descriptions: add more `paragraph` entries to `content`. For inline code / links / bold, nest richer node types — not used by this skill.

## Decoding ADF to plain text

When rendering `detail`, walk the document recursively and join all `text` node values:

```jq
[.. | .text? // empty] | join("\n")
```

This flattens paragraphs, lists, and nested nodes into a single newline-joined string.