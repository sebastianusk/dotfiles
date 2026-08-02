---
name: dk
description: Project manager for dk-digital-bank GitLab projects. Use when the user wants to "open", "work on", "clone", "create", "resync", or "close" a dk-digital-bank project, check project status, or manage GitLab issues/MRs. Handles blueprint↔provisioner workspace pairing.
---

# dk — DK Digital Bank Project Manager

## What I do

- Open dk-digital-bank projects with automatic blueprint ↔ provisioner pairing
- Clone, resync, and create GitLab projects
- Manage tmux sessions for project workspaces
- Track project status and GitLab issues/MRs

## When to use me

Use this skill when the user says things like:
- "open X", "work on X", "dk X"
- "clone <url>", "resync", "close project"
- "create project <name>", "what's dirty", "project status"
- "show issues", "create MR", "review MRs"

## Config

| File | Purpose |
|------|---------|
| `~/Code/dk-digital-bank/dk.yaml` | Workspace cache: pre-computed workspace definitions, descriptions, session names. **Always consult this first.** |

## Hardcoded settings

```
code_root: ~/Code/dk-digital-bank
group_slug: dk-digital-bank
tmuxinator_profile: dev
base_session: 0
tmuxinator_config: ~/.tmuxinator/dev.yml
```

## Dependencies

Required: `fzf`, `glab`, `jq`, `yq`, `tmux`, `tmuxinator`, `git`, `python3`.

## Workflow: Opening a project

When the user says "open X", "work on X", "dk X", or just "dk":

### Step 1: Load cache
Read `~/Code/dk-digital-bank/dk.yaml`.

### Step 2: Match in cache
Run the search helper:
```bash
~/.pi/agent/skills/dk/scripts/search-cache.sh "{query}"
```

Or query with yq directly:
```bash
yq e '.workspaces | to_entries | .[] | "\(.key) | \(.value.description) | session: \(.value.session_name)"' ~/Code/dk-digital-bank/dk.yaml | grep -i "{query}"

# Discovered repos (fallback)
yq e '.discovered | to_entries | .[] | "\(.key) | \(.value)"' ~/Code/dk-digital-bank/dk.yaml | grep -i "{query}"
```

Match against workspace keys, descriptions, session names, and discovered repo keys.

If **exact or high-confidence match** → skip to Step 6 (Open).

If **ambiguous** → present matches, let user pick.

### Step 3: Cache miss — search

**Filesystem:**
```bash
find ~/Code/dk-digital-bank -type d -name "*{query}*" ! -path "*/.git/*" ! -path "*/node_modules/*" 2>/dev/null
```

**Remote — GitLab:**
```bash
glab api "groups/dk-digital-bank/projects?include_subgroups=true&search={query}" | jq -r '.[].path_with_namespace'
```

### Step 4: Process results

**Remote not on disk** — offer to clone:
```
Found on GitLab (not cloned):
  • dk-digital-bank/services/ms-payment
Clone and open? [y/N]
```

**Auto-pair by convention:**
- Group filesystem results by basename
- If same basename appears under `**/provisioner/` AND `**/blueprints/`, pair them
- Compute common ancestor of all paired dirs
- Generate session_name using rules below

**Always confirm** before opening:
```
Workspace: gcp-vm
  Description: GCP VM provisioner module
  Dirs:       platform/provisioner/gcp-vm
  Root:       platform/
  Session:    dk-digital-bank/gcp-vm

No matching blueprint found. Open anyway? [y/N/edit]
```

If user says `edit`, adjust dirs, root, session name, or description. Re-present.

### Step 5: Save to cache
After confirmation, run:
```bash
~/.pi/agent/skills/dk/scripts/save-workspace.sh \
  "{key}" "{description}" "{dir1,dir2,...}" "{common_root}" "{session_name}" "{kind}"
```

### Step 6: Clone/pull if needed
```bash
~/.pi/agent/skills/dk/scripts/pull-workspace.sh "{name}"
```

### Step 7: Open tmux session
```bash
~/.pi/agent/skills/dk/scripts/open-session.sh "{name}"
```

## Session naming rules

| Scenario | session_name |
|----------|-------------|
| Unique name, no ambiguity | `dk-digital-bank/{name}` |
| Ambiguous (multiple suborgs) | `dk-digital-bank/{suborg}/{name}` |
| Single dir, no pairing | `dk-digital-bank/{relpath}` |

## Cache schema (~/Code/dk-digital-bank/dk.yaml)

```yaml
version: 1
generated_at: "ISO timestamp"
code_root: ~/Code/dk-digital-bank

workspaces:
  atlantis:
    description: "Atlantis provisioner + Jago blueprint"
    dirs:
      - platform/provisioner/atlantis
      - platform/jago/blueprints/atlantis
    common_root: platform
    session_name: dk-digital-bank/atlantis
    kind: convention          # convention | manual | adhoc
    last_opened: "2025-01-15T10:30:00Z"

discovered:                    # all repos on disk, keyed by name
  tyk-api-policy: _self-service/tyk-api-policy
  ms-payment: services/ms-payment
  ...

remote_only:                   # repos on GitLab not yet cloned
  - name: some-service
    path_with_namespace: dk-digital-bank/services/some-service
    description: ""
```

## Commands

### `dk` / "open X" / "work on X"
Open a project. Follow the full workflow above.

### `dk clone <gitlab-url>`
```bash
glab repo clone dk-digital-bank/{path} ~/Code/dk-digital-bank/{path}
```
Then confirm workspace, save to cache, open session.

### `dk resync`
```bash
glab api "groups/dk-digital-bank/projects?include_subgroups=true&per_page=100" --paginate | jq -r '.[].path_with_namespace'
python3 ~/.pi/agent/skills/dk/scripts/cache-gen.py
```

### `dk close`
```bash
~/.pi/agent/skills/dk/scripts/close-session.sh
```

### `dk status` / "what's dirty?"
```bash
~/.pi/agent/skills/dk/scripts/status.sh [workspace-name]
```

### `dk create <name>`
```bash
glab repo create "dk-digital-bank/{name}" --private
glab repo clone "dk-digital-bank/{name}" ~/Code/dk-digital-bank/{name}
```
Then confirm workspace, save to cache, open.

### Adding repos to an existing workspace

When the user needs an extra repo added to an already-open workspace (e.g., mid-session), do both:

```bash
# 1. Clone it now (pull-workspace.sh already ran)
glab repo clone dk-digital-bank/{path} ~/Code/dk-digital-bank/{path}

# 2. Persist to cache so future pull-workspace.sh picks it up
yq e '.workspaces.{key}.dirs += ["{path}"]' -i ~/Code/dk-digital-bank/dk.yaml
```

If other metadata also changed (description, session name, etc.), re-run `save-workspace.sh` instead of step 2.

### Issues and MRs
- "show issues for X": `glab issue list -R dk-digital-bank/{path}`
- "create MR for X": `glab mr create`
- "review MRs for X": `glab mr list -R dk-digital-bank/{path}`

## Cache generator

```bash
python3 ~/.pi/agent/skills/dk/scripts/cache-gen.py
```

Scans `~/Code/dk-digital-bank`, applies blueprint↔provisioner pairing, preserves manual entries, writes `~/Code/dk-digital-bank/dk.yaml`.

## Notes
- **Dotfiles** excluded — separate skill.
- **Always confirm** before saving new workspaces to cache.
- Session policy: kill existing session with same name before creating.
- The cache is the source of truth — after first confirmed open, subsequent opens are instant.
