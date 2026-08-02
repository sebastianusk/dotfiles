---
name: docs-lookup
description: Look up current library documentation before writing code — avoid hallucinated APIs
---

# docs-lookup

## When to use me

Use this skill when the user says things like:
- "look up the docs for X", "check the API for X"
- "how do I use X", "what's the correct way to X"
- "does X support Y", "verify the syntax for X"
- "find examples of X"

Also use when you need to verify a library's API, syntax, or usage before writing code.

## Method (try in order)

### 1. Context7 API (preferred)
If `$CONTEXT7_API_KEY` is set:
- Resolve library ID: use `ctx_fetch_and_index` on `https://context7.com/api/resolve?name=<library>&query=<what-you-need>`
- Then query docs: `https://context7.com/api/query?libraryId=<id>&query=<what-you-need>`
- Add header: `Authorization: Bearer $CONTEXT7_API_KEY`

### 2. Convention-based URL construction
For common platforms, construct the docs URL directly:
- **npm**: `https://www.npmjs.com/package/<name>` or the GitHub repo from package.json
- **Python**: `https://pypi.org/project/<name>/` → look for docs link
- **Rust**: `https://docs.rs/<crate>/latest/<crate>/`
- **Go**: `https://pkg.go.dev/<module-path>`
- **GitHub repos**: `https://raw.githubusercontent.com/<org>/<repo>/main/README.md`
- **Known docs sites**: React (`react.dev`), Next.js (`nextjs.org/docs`), Tailwind (`tailwindcss.com/docs`), etc.

Use `ctx_fetch_and_index` to pull in the relevant page, then `ctx_search` to find the specific section.

### 3. Fallback
If nothing else works, search the codebase for existing usage of the library — prefer project conventions over documentation.

## Rules
- Always verify the current API before writing code — don't rely on training data
- Prefer official docs over blog posts or random GitHub issues
- If a library isn't documented, say so rather than guessing the API
