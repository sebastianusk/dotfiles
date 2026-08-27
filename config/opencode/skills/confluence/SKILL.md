---
name: confluence
description: Confluence Cloud page management — list spaces, search pages, get page content, create/update/delete pages. Use when the user says "confluence", "wiki", "search confluence for ...", "show me confluence page ...", "create a confluence page", or similar.
---

# confluence — Confluence Cloud Page Manager

## What I do

- List available Confluence spaces
- List pages within a space (optionally filtered by title)
- Get page content (body, metadata, children)
- Search pages by text across spaces
- Create, update, and delete pages
- Open pages in browser

## When to use me

Use this skill when the user says things like:
- "search confluence for ...", "find confluence pages about ..."
- "show me confluence page <ID>", "get confluence page 12345"
- "list spaces", "what pages are in the ENGINEERING space"
- "create a confluence page", "update that page's body", "delete page 12345"
- "write to my personal space", "create a page in my personal space", "put this in my personal wiki"
- "open confluence page 12345"

## Personal space

The user has a Confluence personal space — use it as the default target whenever the user says "personal space", "my personal space", "my wiki", "write to my space", etc. Do not call `spaces` or `auth-test` to look it up — the key is documented here.

- **URL**: https://bankjago.atlassian.net/wiki/spaces/~7120205f0128e02dcf48dcb903704e63c6431f/overview
- **Space key**: `~7120205f0128e02dcf48dcb903704e63c6431f`
- **Domain**: `bankjago.atlassian.net` (also serves as the `ATLASSIAN_DOMAIN` env var)

Pass the key directly to `--space`:
```bash
./scripts/confluence.sh create --title "My Note" --space "~7120205f0128e02dcf48dcb903704e63c6431f" --body "<p>...</p>"
```

## Required env vars

- `ATLASSIAN_DOMAIN` — e.g. `<you>.atlassian.net`
- `ATLASSIAN_EMAIL` — your Atlassian account email
- `ATLASSIAN_API_TOKEN` — Cloud API token

Auth scheme: HTTP Basic, header `Authorization: Basic base64($ATLASSIAN_EMAIL:$ATLASSIAN_API_TOKEN)`.

The script guards at runtime — if any var is missing it prints the exact unset name and exits 1.

## Commands

All commands run via `./scripts/confluence.sh <subcommand> [opts]` (paths relative to this skill dir).

### `auth-test`
Verify credentials. Caches the space list to `~/.cache/confluence/spaces.json`.
```bash
./scripts/confluence.sh auth-test
```

### `spaces`
List all available spaces (from cache; run `auth-test` to refresh).
```bash
./scripts/confluence.sh spaces
```

### `pages`
List pages in a space, optionally filtered by title.
```bash
./scripts/confluence.sh pages --space ENG
./scripts/confluence.sh pages --space ENG --title "Design Doc"
./scripts/confluence.sh pages --space ENG --limit 10
```

### `get`
Get a page by ID — shows metadata, body, and child pages.
```bash
./scripts/confluence.sh get 123456
./scripts/confluence.sh get 123456 --plain           # readable plain-text body
./scripts/confluence.sh get 123456 --format atlas_doc_format
```
Use `--plain` for agent consumption — converts storage-format HTML to markdown-like text (headings, lists, code, bold, page/jira references).

### `search`
Full-text search across pages. Uses CQL `text ~ "..."`.
```bash
./scripts/confluence.sh search "onboarding"
./scripts/confluence.sh search "architecture" --space ENG
./scripts/confluence.sh search "architecture" --space ENG --limit 5
```

### `create`
Create a new page. Requires title, space key, and body (storage-format HTML).
```bash
./scripts/confluence.sh create --title "My Page" --space ENG --body "<p>Hello world</p>"
./scripts/confluence.sh create --title "Sub-page" --space ENG --body "<p>child</p>" --parent 123456
```

### `update`
Update a page's title and/or body. Automatically increments version if `--version` is omitted.
```bash
./scripts/confluence.sh update 123456 --title "New Title"
./scripts/confluence.sh update 123456 --body "<p>Updated content</p>"
./scripts/confluence.sh update 123456 --title "V2" --body "<p>Both</p>" --version 3
```

### `delete`
Delete a page. Requires `--force` to prevent accidents.
```bash
./scripts/confluence.sh delete 123456 --force
```

### `open`
Open a page in the browser (macOS `open`).
```bash
./scripts/confluence.sh open 123456
```

### Help
```bash
./scripts/confluence.sh --help
```

## Notes

- The script shares the same `ATLASSIAN_*` env vars as the jira skill.
- Space list is cached in `~/.cache/confluence/spaces.json`; re-run `auth-test` to refresh.
- For endpoint and body format details see [references/api-reference.md](references/api-reference.md).
- Page body is Confluence storage format (HTML-like XML). Use `<p>`, `<h1>`-`<h6>`, `<ul>/<li>`, `<code>`, `<strong>`, etc.
- Always run `auth-test` first to verify credentials and prime the cache.
