# projects.zsh — Project Manager for Zsh

A single fzf-powered picker to open any project in tmux via tmuxinator,
plus a clone command for GitHub repos that lands under a unified code root.

## Quick start

1. `cp config/zsh/project/projects.yaml.example ~/.config/projects.yaml`
2. `export PROJECT_YAML="$HOME/.config/projects.yaml"` (or set wherever you keep env)
3. In `config/zsh/zshrc`, source `$HOME/dotfiles/config/zsh/project/projects.zsh`
   after fzf is available.
4. `pj` — pick a project.
5. `pj clone git@github.com:owner/repo.git` — clone + open.

## Concepts

Every project is a **directory on disk**.  The picker lists projects from four
sources, all merged into one fzf stream.  Each source produces rows with a
prefix so you can type to narrow (`gitlab:`, `github:`, `static:`, `dir:`).

| Prefix   | Source                   | How it appears                     |
|----------|--------------------------|------------------------------------|
| `gitlab:`| GitLab group API         | Full repos (leaf projects)         |
| `dir:`   | Synthesised from GitLab  | Parent directories (non-repo)      |
| `github:`| Filesystem scan          | Cloned repos under github.code_root|
| `static:`| YAML static list         | Any directory you configure        |

## Configuration (`$PROJECT_YAML`)

Accepts a single YAML file.  If `PROJECT_YAML` is not set, defaults to
`$HOME/dotfiles/config/zsh/project/projects.yaml`.

Schema:

```yaml
tmuxinator_profile: dev           # default tmuxinator profile name
base_session: base                # default session name for pj close
tmuxinator_config: ~/.tmuxinator/dev.yml  # path to the profile YAML

gitlab_groups:                    # array — scan GitLab via glab
  - slug: dk-digital-bank
    code_root: ~/Code/dk-digital-bank

github:                           # single GitHub root (filesystem scan)
  code_root: ~/Code/github

static_projects:                  # hand-picked directories
  - path: ~/dotfiles
  - path: ~/Documents/brain

# optional per-source cache overrides (derive from XDG_CACHE_HOME by default):
# gitlab_cache: ~/.cache/dotfiles/projects-glab.txt
```

- `gitlab_groups` is an array: each entry has a `slug` (GitLab group path)
  and a `code_root` where repos land on disk.
  Clone path: `{code_root}/{path_with_namespace}` with the leading
  `{slug}/` **stripped**.  E.g. slug `dk-digital-bank`, repo
  `dk-digital-bank/services/ms-account` → `~/Code/dk-digital-bank/services/ms-account`.
  All groups must use the **same GitLab instance** (multi-instance not
  supported).
- `github.code_root` is the parent for all `pj clone` targets and filesystem
  discovery.  Layout: `{code_root}/{owner}/{repo}`.
- `static_projects` entries are directories that always appear in the picker.
  Optional `label` overrides the display name shown in fzf.
- `base_session` (optional, default `base`) — the tmux session that `pj close`
  switches back to.
- `tmuxinator_profile` (optional, default `dev`) — name of the tmuxinator
  project to start.
- `tmuxinator_config` (optional, default `~/.config/tmuxinator/dev.yml`) —
  path to the profile YAML file; passed to tmuxinator with `-p`.

## Commands

### `pj`

1. Merge sources into one fzf list (see Sources and fzf-format below).
2. When the user picks a row:
   - **repo** (gitlab / github): clone or update to `target_dir`.
     GitLab uses `glab repo clone`; GitHub uses `git clone` (or `git pull`
     if `.git` exists).
   - **dir / static**: ensure directory exists (`mkdir -p`).
   - Session name = `basename(target_dir)`.
   - If a tmux session with that name exists → `tmux kill-session -t <name>`.
   - `tmuxinator start <profile> -n <name> -p <config>` with cwd at
     `target_dir`.
   - If already **inside tmux** (`TMUX` set): `tmux switch-client -t <name>`.
   - If **outside tmux**: `tmux attach -t <name>`.

### `pj clone <ssh-url>`

- Accepts SSH URLs: `git@github.com:owner/repo.git` (`.git` suffix optional).
  Rejects non-`github.com` hosts and HTTPS URLs.
- Computes path: `{github.code_root}/{owner}/{repo}`.
- `mkdir -p` → `git clone <url> <path>` (or `git pull` if `.git` exists).
- **Then** runs the same "open in tmux" flow as `pj` pick (see above).
- The project appears on the **next** `pj` invocation automatically
  (filesystem scan, no API).

### `pj close`

- Must be run **inside tmux** (`TMUX` set), otherwise prints an error and
  exits non-zero.
- Resolves the current session name (`tmux display-message -p '#S'`).
- No-op if the current session is already `base_session`.
- If the `base_session` does not exist, creates a detached one:
  `tmux new-session -ds <base_session>`.
- Switches client to `base_session` first (`tmux switch-client -t
  <base_session>`), then destroys the session that was left
  (`tmux kill-session -t <previous>`).

## Session policy

- Session name = **basename** of the project directory (no parent
  disambiguation).
- **Replace**: if a tmux session with that name exists, kill it first
  (`tmux kill-session -t <name>`), then start tmuxinator with `-n <name>`
  so the new session carries the exact name.
- `pj close` switches the client to the `base_session` (default `base`) and
  kills the current session.
- Inside tmux: `tmux switch-client` to the new session. Outside tmux:
  `tmux attach` to it.

## Required tools

All four must be present for `projects.zsh` to load, nothing is optional.

| Tool        | Used for                                  |
|-------------|--------------------------------------------|
| `fzf`       | Picker                                    |
| `glab`      | GitLab API (group project listing)        |
| `jq`        | JSON parsing in sync helpers              |
| `yq`        | YAML config parsing                       |
| `tmux`      | Session creation / attach / kill          |
| `tmuxinator`| Layout from profile (e.g. `dev.yml`)      |

## Sources

### fzf row format

Each row in the picker has the form `prefix:display_text`.  The prefix
(`gitlab:`, `dir:`, `github:`, `static:`) drives the action on selection.
An internal associative array maps the full row (or a key derived from it)
to the resolved `target_dir` on disk, so parsing after selection is a
simple lookup.

| Row example                     | Type    | `target_dir` calc                        |
|---------------------------------|---------|------------------------------------------|
| `gitlab:dk-digital-bank/services/ms-account` | repo | `{code_root}/services/ms-account` |
| `dir:dk-digital-bank/services`  | folder | `{code_root}/services` (strip slug)      |
| `github:harness/ff-proxy`       | repo   | `{github.code_root}/harness/ff-proxy`    |
| `static:dotfiles`               | static | Look up from YAML config                  |

### GitLab (dynamic)

- One cache file per group (default under `$XDG_CACHE_HOME/dotfiles/`).
- **Full sync** (`ctrl-u` in fzf): `glab api groups/{slug}/projects?include_subgroups=true&per_page=100 --paginate` → all `path_with_namespace` rows.
- **Targeted sync** (`ctrl-r` in fzf): `glab api groups/{slug}/projects?include_subgroups=true&search={query}` → refines current view.
- Clone uses `glab repo clone <path_with_namespace> <target_dir>` (handles
  auth and SSH automatically).
- **Synthesised `dir:` rows** (depth 0 — includes the bare group directory):
  treat every **parent prefix** of each repo path as a non-repo directory
  pick.  E.g. `dk-digital-bank/services/ms-account` yields rows:
  - `dir:dk-digital-bank`
  - `dir:dk-digital-bank/services`
  - `gitlab:dk-digital-bank/services/ms-account`
- Duplicates are collapsed; a prefix that is also a real repo is shown as
  `gitlab:` only.

### GitHub (filesystem scan)

- Walk `{github.code_root}/*/*/.git` — every matching `owner/repo` becomes a
  `github:` row.
- No API, no caching — always live from the filesystem.
- Items appear automatically after `pj clone`.

### Static

- Read directly from `static_projects` in the YAML config.
- Each entry must have `path`; optional `label` overrides the display name.

## Key bindings (while fzf is open)

| Key        | Action                                         |
|------------|------------------------------------------------|
| Enter      | Pick repo/dir → open tmux session              |
| Ctrl-R     | Targeted sync (search GitLab with current query)|
| Ctrl-U     | Full sync (pull all GitLab projects)           |
| Ctrl-C/Esc | Cancel                                        |
