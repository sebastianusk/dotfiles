---
name: dk
description: GitLab repo explorer & cloner for dk-digital-bank. Use when the user wants to search, clone, create, or check status of GitLab repos. No workspace cache or tmux sessions — repos are tracked by task files in the Obsidian vault.
---

# dk — DK Digital Bank Repo Utility

## What I do

- Search dk-digital-bank GitLab repos (remote + on-disk)
- Clone repos from GitLab
- Create new repos on GitLab
- Check repo status (what's dirty, what branches)
- List repos on disk
- Manage issues and MRs

## When to use me

Use this skill when the user says things like:
- "search for X", "find repo X", "what repos match Y"
- "clone X", "get X"
- "create repo X", "new repo X"
- "what's dirty", "repo status", "git status all"
- "show issues for X", "create MR for X", "review MRs for X"

## Hardcoded settings

```
code_root: ~/Code/dk-digital-bank
group_slug: dk-digital-bank
```

## Dependencies

Required: `glab`, `jq`, `git`, `fzf`.

## Workflows

### Search for a repo

**Remote — GitLab API:**
```bash
glab api "groups/dk-digital-bank/projects?include_subgroups=true&search={query}" | jq -r '.[].path_with_namespace' | head -20
```

**On-disk — filesystem:**
```bash
find ~/Code/dk-digital-bank -type d -name ".git" -maxdepth 5 ! -path "*/node_modules/*" 2>/dev/null | sed 's|/.git||' | sed "s|$HOME/Code/dk-digital-bank/||" | grep -i "{query}" | sort
```

**If remote found but not on disk** → offer to clone.
**If on disk** → print the local path.

### Clone a repo

```bash
glab repo clone dk-digital-bank/{path} ~/Code/dk-digital-bank/{path}
```

The `{path}` is the full GitLab path within the group (e.g. `services/ms-payment`, `platform/provisioner/atlantis`). Ensure parent directories exist.

### Create a repo

```bash
glab repo create "dk-digital-bank/{name}" --private
glab repo clone "dk-digital-bank/{name}" ~/Code/dk-digital-bank/{name}
```

### Check repo status / what's dirty

```bash
find ~/Code/dk-digital-bank -name ".git" -maxdepth 5 ! -path "*/node_modules/*" 2>/dev/null | while read gitdir; do
  repo=$(dirname "$gitdir")
  dirty=$(git -C "$repo" status --porcelain 2>/dev/null)
  if [ -n "$dirty" ]; then
    count=$(echo "$dirty" | wc -l | xargs)
    rel=$(echo "$repo" | sed "s|$HOME/Code/dk-digital-bank/||")
    echo "  $rel — $count file(s)"
  fi
done
```

If no repos have uncommitted changes, report "All clean."

### List repos on disk

```bash
find ~/Code/dk-digital-bank -name ".git" -maxdepth 5 ! -path "*/node_modules/*" 2>/dev/null | sed 's|/.git||' | sed "s|$HOME/Code/dk-digital-bank/||" | sort
```

### Open repo in editor
```bash
cd ~/Code/dk-digital-bank/{path} && exec $EDITOR .
```

### Issues and MRs

- "show issues for X": `glab issue list -R dk-digital-bank/{path}`
- "create MR for X": Pre-pull latest default branch, then open MR. Runs in the repo working copy:
  ```bash
  repo=~/Code/dk-digital-bank/{path}
  default=$(git -C "$repo" symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|^origin/||')
  [ -z "$default" ] && default=main
  git -C "$repo" fetch origin
  git -C "$repo" merge --ff-only "origin/$default" || {
    echo "⚠️  Cannot fast-forward origin/$default — rebase or merge manually first, then run:"
    echo "    glab mr create -R dk-digital-bank/{path}"
    exit 1
  }
  glab mr create -R dk-digital-bank/{path}
  ```
  Falls back to `main` if `origin/HEAD` isn't set (handles repos where the default is `master` too — change the fallback if your org uses `master`).
- "review MRs for X": `glab mr list -R dk-digital-bank/{path}`

### Resync all cloned repos

Pull all cloned repos on disk:
```bash
find ~/Code/dk-digital-bank -name ".git" -maxdepth 5 ! -path "*/node_modules/*" 2>/dev/null | while read gitdir; do
  repo=$(dirname "$gitdir")
  rel=$(echo "$repo" | sed "s|$HOME/Code/dk-digital-bank/||")
  echo "=== $rel ==="
  git -C "$repo" pull --ff-only 2>&1
done
```

## Notes

- No workspace cache (dk.yaml) — all operations are on-demand via glab + filesystem.
- No tmux sessions — repos are just directories. Navigate via cd or your editor.
- Tasks track which repos they use via a `## Repositories` section in the Obsidian task file (full GitLab URLs). Read this section to see which repos to clone or pull.
