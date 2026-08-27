# Confluence Cloud REST API Reference (v2)

Load-on-demand cheat-sheet for the endpoints and body formats used by `scripts/confluence.sh`.

## Base URL

### v2 API (pages, spaces)
```
https://$ATLASSIAN_DOMAIN/wiki/api/v2
```

### v1 REST API (search only)
```
https://$ATLASSIAN_DOMAIN/wiki/rest/api
```

## Auth

HTTP Basic, header:
```
Authorization: Basic base64($ATLASSIAN_EMAIL:$ATLASSIAN_API_TOKEN)
Accept: application/json
Content-Type: application/json
```

A 401 means bad `ATLASSIAN_EMAIL` / `ATLASSIAN_API_TOKEN` combination. A 404 means the page/space doesn't exist. A 400 usually means bad body format.

## Endpoints used

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/wiki/api/v2/spaces?limit=250` | List all spaces (cached) |
| GET | `/wiki/api/v2/spaces/{spaceId}/pages?limit=&sort=-modified-date` | List pages in a space |
| GET | `/wiki/api/v2/pages/{id}?body-format=storage` | Get page with body |
| GET | `/wiki/api/v2/pages/{id}/children?limit=50` | Get child pages |
| GET | `/wiki/rest/api/search?cql=...&limit=...` | Full-text search (CQL) |
| POST | `/wiki/api/v2/pages` | Create page |
| PUT | `/wiki/api/v2/pages/{id}` | Update page |
| DELETE | `/wiki/api/v2/pages/{id}` | Delete page |

## Create body

```json
{
  "spaceId": "123456789",
  "status": "current",
  "title": "Page Title",
  "body": {
    "representation": "storage",
    "value": "<p>HTML content</p>"
  },
  "parentId": "987654321"   // optional — omit for top-level pages
}
```

## Update body

```json
{
  "id": "123456789",
  "status": "current",
  "spaceId": "123",
  "title": "Updated Title",
  "body": {
    "representation": "storage",
    "value": "<p>Updated HTML content</p>"
  },
  "version": {
    "number": 2,
    "message": ""
  }
}
```

`body` is optional on update — omit it to only change the title (version still required).

## Page response shape (v2)

```json
{
  "id": "123456789",
  "status": "current",
  "title": "My Page",
  "spaceId": "123",
  "parentId": "987654321",
  "version": {
    "number": 1,
    "message": "",
    "authorId": "5f...",
    "createdAt": "..."
  },
  "body": {
    "storage": {
      "value": "<p>content</p>",
      "representation": "storage"
    }
  },
  "createdAt": "2024-01-01T00:00:00.000Z"
}
```

## Space key → Space ID resolution

The script maintains a local cache at `~/.cache/confluence/spaces.json`:
```json
[
  {"id": "123456789", "key": "ENG", "name": "Engineering"},
  ...
]
```

Run `auth-test` to refresh the cache.

## CQL (Confluence Query Language)

Used for full-text search. Patterns:

```
type=page AND text ~ "query"
type=page AND text ~ "query" AND space = "ENG"
```

CQL reference: https://developer.atlassian.com/server/confluence/confluence-search-syntax/

## Storage format (body content)

Confluence pages use a subset of HTML ("storage format"). Common elements:

| Markup | Storage format |
|--------|---------------|
| Paragraph | `<p>text</p>` |
| Heading 1-6 | `<h1>...</h1>` through `<h6>...</h6>` |
| Unordered list | `<ul><li>...</li></ul>` |
| Ordered list | `<ol><li>...</li></ol>` |
| Inline code | `<code>mono</code>` |
| Bold | `<strong>text</strong>` |
| Italic | `<em>text</em>` |
| Link | `<a href="https://...">text</a>` |
| Line break | `<br />` |

For tables, macros, and richer content, use the Confluence editor to compose, then inspect the storage format via `get`.
