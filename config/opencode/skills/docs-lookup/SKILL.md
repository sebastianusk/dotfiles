---
name: docs-lookup
description: Look up current library, framework, SDK, API, CLI, and cloud-service documentation before writing code; use official URLs for other current web facts
---

# docs-lookup

## When to use me

Use this skill when the user asks about, or you need to verify:
- A library, framework, SDK, API, CLI tool, or cloud service
- Current syntax, configuration, supported features, or usage examples
- A product, release, policy, or other current web fact

Always verify library-specific APIs and current tool behavior before writing code. Do not rely on remembered or possibly stale API details.

## Method

### 1. Library and tool documentation: Context7 MCP

Use the configured `context7` MCP server first for library, framework, SDK, API, CLI, and cloud-service documentation.

- Resolve the exact library or product identifier before querying documentation when needed.
- Query only the relevant concept and version, if a version is specified.
- Prefer the official documentation represented by the Context7 result.
- Check the returned examples and API details against the user's requested version.

### 2. Other current web facts: official URLs

For current facts that are not library or tool documentation, fetch the official source URL directly. Prefer:
- The vendor's product, status, changelog, or policy page
- The project's official website or repository
- An official government or standards body source

Do not treat search snippets, blogs, or third-party summaries as authoritative when an official source is available. If an official source cannot be found, say so and identify the source used.

### 3. Fallback

If the relevant documentation is unavailable, inspect the codebase for existing usage and state that the answer is based on project conventions rather than verified current documentation. Never invent an API or configuration key.

## Rules

- Use the configured `context7` MCP, not a manually constructed Context7 HTTP API call or an unrelated web search, for supported documentation lookups.
- Use official URLs for other current web facts.
- Verify current information before implementing code or configuration.
- Include the relevant source or documentation reference when reporting non-obvious findings.
