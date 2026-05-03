# projects.zsh — Project Manager for Zsh
# See project/README.md for full specification.

# =============================================================================
# DEFAULTS & DEPENDENCY CHECK
# =============================================================================

: "${PROJECT_YAML:=$HOME/dotfiles/config/zsh/project/projects.yaml}"

local _pj_missing=()
for _pj_dep in fzf glab jq yq tmux tmuxinator git; do
    command -v "$_pj_dep" >/dev/null 2>&1 || _pj_missing+=("$_pj_dep")
done
unset _pj_dep
if (( ${#_pj_missing[@]} )); then
    print -r "pj: missing required tools: ${_pj_missing[*]}" >&2
    unset _pj_missing
    return 1
fi
unset _pj_missing

if [[ ! -f "$PROJECT_YAML" ]]; then
    print -r "pj: config not found: $PROJECT_YAML" >&2
    print -r "pj: copy projects.yaml.example and set PROJECT_YAML" >&2
    return 1
fi

# =============================================================================
# CACHE DIRECTORY
# =============================================================================

_PJ_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles"
_PJ_LIST_FILE="$_PJ_CACHE_DIR/pj-list"
_PJ_HELPERS_DIR="$_PJ_CACHE_DIR/helpers"
mkdir -p "$_PJ_CACHE_DIR" "$_PJ_HELPERS_DIR"

# =============================================================================
# CONFIG LOADING (cached at source time)
# =============================================================================

_PJ_TMUX_PROFILE=$(yq e '.tmuxinator_profile // "dev"' "$PROJECT_YAML")
_PJ_BASE_SESSION=$(yq e '.base_session // "base"' "$PROJECT_YAML")
_PJ_TMUX_CONFIG=$(yq e '.tmuxinator_config // "$HOME/.tmuxinator/dev.yml"' "$PROJECT_YAML")
_PJ_TMUX_CONFIG=${~_PJ_TMUX_CONFIG}
_PJ_GITHUB_ROOT=$(yq e '.github.code_root // ""' "$PROJECT_YAML")
[[ -n "$_PJ_GITHUB_ROOT" ]] && _PJ_GITHUB_ROOT=${~_PJ_GITHUB_ROOT}

# GitLab groups as parallel arrays (zsh 1-indexed)
local _pj_gl_count=$(yq e '.gitlab_groups | length' "$PROJECT_YAML")
_PJ_GL_SLUGS=()
_PJ_GL_ROOTS=()
_PJ_GL_CACHES=()
for (( _pj_i=0; _pj_i<_pj_gl_count; _pj_i++ )); do
    _PJ_GL_SLUGS+=( "$(yq e ".gitlab_groups[$_pj_i].slug" "$PROJECT_YAML")" )
    local _pj_root=$(yq e ".gitlab_groups[$_pj_i].code_root" "$PROJECT_YAML")
    _pj_root=${~_pj_root}
    _PJ_GL_ROOTS+=( "$_pj_root" )
    _PJ_GL_CACHES+=( "$_PJ_CACHE_DIR/projects-glab-$(yq e ".gitlab_groups[$_pj_i].slug" "$PROJECT_YAML").txt" )
done
unset _pj_i _pj_root _pj_gl_count

# =============================================================================
# HELPER SCRIPTS (for fzf bind subshells)
# =============================================================================

# build-list.sh: regenerates the merged list file.
# Reads PROJECT_YAML from env. Calls yq/jq/find directly.
cat > "$_PJ_HELPERS_DIR/build-list.sh" << 'BUILDLIST_EOF'
#!/bin/zsh
set -e
PROJECT_YAML="${PROJECT_YAML:-$HOME/dotfiles/config/zsh/project/projects.yaml}"
PJ_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles"
PJ_LIST_FILE="$PJ_CACHE_DIR/pj-list"
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

# Static projects
scount=$(yq e '.static_projects | length' "$PROJECT_YAML")
for (( i=0; i<scount; i++ )); do
    spath=$(yq e ".static_projects[$i].path" "$PROJECT_YAML")
    slabel=$(yq e ".static_projects[$i].label // \"\"" "$PROJECT_YAML")
    spath=${~spath}
    if [[ -n "$slabel" ]]; then
        printf 'static:%s\t%s\n' "$slabel" "$spath"
    else
        printf 'static:%s\t%s\n' "${spath:t}" "$spath"
    fi
done >> "$tmp"

# GitLab groups
glab_count=$(yq e '.gitlab_groups | length' "$PROJECT_YAML")
for (( gi=0; gi<glab_count; gi++ )); do
    slug=$(yq e ".gitlab_groups[$gi].slug" "$PROJECT_YAML")
    code_root=$(yq e ".gitlab_groups[$gi].code_root" "$PROJECT_YAML")
    code_root=${~code_root}
    cachefile="$PJ_CACHE_DIR/projects-glab-${slug}.txt"
    [[ ! -f "$cachefile" ]] && continue
    repo_set=$(mktemp)
    cp "$cachefile" "$repo_set"
    dir_set=$(mktemp)
    while IFS= read -r pwp; do
        rel="${pwp#$slug/}"
        printf 'gitlab:%s\t%s/%s\n' "$pwp" "$code_root" "$rel"
        local current="$slug"
        printf '%s\n' "$current" >> "$dir_set"
        local -a parts=("${(@s:/:)rel}")
        for (( i=1; i<${#parts[@]}; i++ )); do
            current="${current}/${parts[i]}"
            printf '%s\n' "$current" >> "$dir_set"
        done
    done < "$repo_set" >> "$tmp"
    sort -u "$dir_set" | while IFS= read -r prefix; do
        if ! grep -qxF "$prefix" "$repo_set" 2>/dev/null; then
            if [[ "$prefix" == "$slug" ]]; then
                printf 'dir:%s\t%s\n' "$prefix" "$code_root"
            else
                local rel="${prefix#$slug/}"
                printf 'dir:%s\t%s/%s\n' "$prefix" "$code_root" "$rel"
            fi
        fi
    done >> "$tmp"
    rm -f "$repo_set" "$dir_set"
done

# GitHub filesystem scan
gh_root=$(yq e '.github.code_root // ""' "$PROJECT_YAML")
if [[ -n "$gh_root" ]]; then
    gh_root=${~gh_root}
    if [[ -d "$gh_root" ]]; then
        for owner_dir in "$gh_root"/*(N/); do
            for repo_dir in "$owner_dir"/*(N/); do
                if [[ -d "$repo_dir/.git" ]]; then
                    owner="${owner_dir:t}"
                    repo="${repo_dir:t}"
                    printf 'github:%s/%s\t%s/%s/%s\n' "$owner" "$repo" "$gh_root" "$owner" "$repo"
                fi
            done
        done >> "$tmp"
    fi
fi

sort -u -t$'\t' -k1,1 "$tmp" > "$PJ_LIST_FILE"
BUILDLIST_EOF
chmod +x "$_PJ_HELPERS_DIR/build-list.sh"

# sync-full.sh: full glab sync + list rebuild
cat > "$_PJ_HELPERS_DIR/sync-full.sh" << 'SYNCFULL_EOF'
#!/bin/zsh
set -e
PROJECT_YAML="${PROJECT_YAML:-$HOME/dotfiles/config/zsh/project/projects.yaml}"
PJ_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles"
GLAB_COUNT=$(yq e '.gitlab_groups | length' "$PROJECT_YAML")
for (( i=0; i<GLAB_COUNT; i++ )); do
    slug=$(yq e ".gitlab_groups[$i].slug" "$PROJECT_YAML")
    cachefile="$PJ_CACHE_DIR/projects-glab-${slug}.txt"
    glab api "groups/${slug}/projects?include_subgroups=true&per_page=100" --paginate \
        | jq -r '.[].path_with_namespace' | sort -u > "$cachefile"
done
PROJECT_YAML="$PROJECT_YAML" "$PJ_CACHE_DIR/helpers/build-list.sh"
SYNCFULL_EOF
chmod +x "$_PJ_HELPERS_DIR/sync-full.sh"

# sync-search.sh: targeted glab sync + list rebuild
cat > "$_PJ_HELPERS_DIR/sync-search.sh" << 'SYNCSEARCH_EOF'
#!/bin/zsh
set -e
PROJECT_YAML="${PROJECT_YAML:-$HOME/dotfiles/config/zsh/project/projects.yaml}"
PJ_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles"
QUERY="$1"
GLAB_COUNT=$(yq e '.gitlab_groups | length' "$PROJECT_YAML")
for (( i=0; i<GLAB_COUNT; i++ )); do
    slug=$(yq e ".gitlab_groups[$i].slug" "$PROJECT_YAML")
    cachefile="$PJ_CACHE_DIR/projects-glab-${slug}.txt"
    glab api "groups/${slug}/projects?include_subgroups=true&search=${QUERY}" \
        | jq -r '.[].path_with_namespace' >> "$cachefile"
    sort -u "$cachefile" -o "$cachefile"
done
PROJECT_YAML="$PROJECT_YAML" "$PJ_CACHE_DIR/helpers/build-list.sh"
SYNCSEARCH_EOF
chmod +x "$_PJ_HELPERS_DIR/sync-search.sh"

# =============================================================================
# GITLAB SYNC (in-shell)
# =============================================================================

_pj_glab_full_sync() {
    local slug=$1 cachefile=$2
    print -r "Syncing $slug..." >&2
    glab api "groups/${slug}/projects?include_subgroups=true&per_page=100" --paginate \
        | jq -r '.[].path_with_namespace' | sort -u > "$cachefile"
}

_pj_glab_targeted_sync() {
    local slug=$1 query=$2 cachefile=$3
    print -r "Searching $slug for: $query..." >&2
    glab api "groups/${slug}/projects?include_subgroups=true&search=${query}" \
        | jq -r '.[].path_with_namespace' >> "$cachefile"
    sort -u "$cachefile" -o "$cachefile"
}

_pj_glab_ensure_caches() {
    local i
    for (( i=1; i<=${#_PJ_GL_SLUGS[@]}; i++ )); do
        if [[ ! -f "${_PJ_GL_CACHES[i]}" ]]; then
            _pj_glab_full_sync "${_PJ_GL_SLUGS[i]}" "${_PJ_GL_CACHES[i]}"
        fi
    done
}

# =============================================================================
# LIST BUILDER (in-shell)
# =============================================================================

_pj_build_list() {
    local i gi slug code_root cachefile pwp rel prefix spath slabel scount
    local tmp=$(mktemp)
    trap 'rm -f "$tmp"' EXIT

    # Static projects
    scount=$(yq e '.static_projects | length' "$PROJECT_YAML")
    for (( i=0; i<scount; i++ )); do
        spath=$(yq e ".static_projects[$i].path" "$PROJECT_YAML")
        slabel=$(yq e ".static_projects[$i].label // \"\"" "$PROJECT_YAML")
        spath=${~spath}
        if [[ -n "$slabel" ]]; then
            printf 'static:%s\t%s\n' "$slabel" "$spath"
        else
            printf 'static:%s\t%s\n' "${spath:t}" "$spath"
        fi
    done >> "$tmp"

    # GitLab groups
    for (( gi=1; gi<=${#_PJ_GL_SLUGS[@]}; gi++ )); do
        slug="${_PJ_GL_SLUGS[gi]}"
        code_root="${_PJ_GL_ROOTS[gi]}"
        cachefile="${_PJ_GL_CACHES[gi]}"
        [[ ! -f "$cachefile" ]] && continue

        local repo_set=$(mktemp)
        local dir_set=$(mktemp)
        while IFS= read -r pwp; do
            rel="${pwp#${slug}/}"
            printf 'gitlab:%s\t%s/%s\n' "$pwp" "$code_root" "$rel"
            local current="$slug"
            printf '%s\n' "$current" >> "$dir_set"
            local -a parts=("${(@s:/:)rel}")
            for (( i=1; i<${#parts[@]}; i++ )); do
                current="${current}/${parts[i]}"
                printf '%s\n' "$current" >> "$dir_set"
            done
        done < "$cachefile" >> "$tmp"

        sort -u "$dir_set" | while IFS= read -r prefix; do
            if ! grep -qxF "$prefix" "$repo_set" 2>/dev/null; then
                if [[ "$prefix" == "$slug" ]]; then
                    printf 'dir:%s\t%s\n' "$prefix" "$code_root"
                else
                    local rel="${prefix#${slug}/}"
                    printf 'dir:%s\t%s/%s\n' "$prefix" "$code_root" "$rel"
                fi
            fi
        done >> "$tmp"
        rm -f "$repo_set" "$dir_set"
    done

    # GitHub filesystem scan
    if [[ -n "$_PJ_GITHUB_ROOT" && -d "$_PJ_GITHUB_ROOT" ]]; then
        local owner_dir repo_dir owner repo
        for owner_dir in "$_PJ_GITHUB_ROOT"/*(N/); do
            for repo_dir in "$owner_dir"/*(N/); do
                if [[ -d "$repo_dir/.git" ]]; then
                    owner="${owner_dir:t}"
                    repo="${repo_dir:t}"
                    printf 'github:%s/%s\t%s/%s/%s\n' "$owner" "$repo" "$_PJ_GITHUB_ROOT" "$owner" "$repo"
                fi
            done
        done >> "$tmp"
    fi

    sort -u -t$'\t' -k1,1 "$tmp"
    rm -f "$tmp"
}

# =============================================================================
# REPO ENSURE & TMUX OPEN
# =============================================================================

_pj_ensure_glab_repo() {
    local target_dir=$1 pwp=$2
    if [[ -d "$target_dir/.git" ]]; then
        print -r "Updating $pwp..." >&2
        git -C "$target_dir" pull
    else
        print -r "Cloning $pwp..." >&2
        mkdir -p "$(dirname "$target_dir")"
        glab repo clone "$pwp" "$target_dir"
    fi
}

_pj_open_dir() {
    local target_dir=$1
    local session_name="${target_dir:t}"

    # Kill existing session with same name
    tmux kill-session -t "$session_name" 2>/dev/null

    # Start tmuxinator with explicit name and config
    (cd "$target_dir" && tmuxinator start "$_PJ_TMUX_PROFILE" -n "$session_name" -p "$_PJ_TMUX_CONFIG")

    # Attach or switch
    if [[ -n "$TMUX" ]]; then
        tmux switch-client -t "$session_name"
    else
        tmux attach -t "$session_name"
    fi
}

# =============================================================================
# FZF PICKER
# =============================================================================

_pj_pick() {
    _pj_glab_ensure_caches
    _pj_build_list > "$_PJ_LIST_FILE"

    local selection
    selection=$(\fzf < "$_PJ_LIST_FILE" \
        --delimiter=$'\t' \
        --with-nth=1 \
        --header="ENTER: Open | Ctrl-R: Search | Ctrl-U: Full sync" \
        --bind "ctrl-u:execute-silent(PROJECT_YAML='$PROJECT_YAML' '$_PJ_HELPERS_DIR/sync-full.sh')+reload(cat '$_PJ_LIST_FILE')" \
        --bind "ctrl-r:execute-silent(PROJECT_YAML='$PROJECT_YAML' '$_PJ_HELPERS_DIR/sync-search.sh' {q})+reload(cat '$_PJ_LIST_FILE')" \
    ) || return 0

    [[ -z "$selection" ]] && return 0

    local kind target_dir display pwp
    kind="${selection%%:*}"
    target_dir="${selection#*$'\t'}"

    case "$kind" in
        gitlab)
            display="${selection%%$'\t'*}"
            pwp="${display#gitlab:}"
            _pj_ensure_glab_repo "$target_dir" "$pwp"
            _pj_open_dir "$target_dir"
            ;;
        github)
            _pj_open_dir "$target_dir"
            ;;
        dir)
            mkdir -p "$target_dir"
            _pj_open_dir "$target_dir"
            ;;
        static)
            _pj_open_dir "$target_dir"
            ;;
        *)
            print -r "pj: unknown kind: $kind" >&2
            return 1
            ;;
    esac
}

# =============================================================================
# CLONE & CLOSE
# =============================================================================

_pj_clone() {
    local url=$1
    # Accept git@github.com:owner/repo.git or git@github.com:owner/repo
    if [[ "$url" != git@github.com:* ]]; then
        print -r "pj clone: only GitHub SSH URLs are supported (git@github.com:owner/repo.git)" >&2
        return 1
    fi
    local path_part="${url#git@github.com:}"
    path_part="${path_part%.git}"
    local owner="${path_part%%/*}"
    local repo="${path_part#*/}"
    local target_dir="$_PJ_GITHUB_ROOT/$owner/$repo"

    if [[ -z "$_PJ_GITHUB_ROOT" ]]; then
        print -r "pj clone: github.code_root not set in $PROJECT_YAML" >&2
        return 1
    fi

    if [[ -d "$target_dir/.git" ]]; then
        print -r "Updating $owner/$repo..." >&2
        git -C "$target_dir" pull
    else
        print -r "Cloning $url..." >&2
        mkdir -p "$(dirname "$target_dir")"
        git clone "$url" "$target_dir"
    fi

    _pj_open_dir "$target_dir"
}

_pj_close() {
    if [[ -z "$TMUX" ]]; then
        print -r "pj close: not inside tmux" >&2
        return 1
    fi

    local current base="$_PJ_BASE_SESSION"
    current=$(tmux display-message -p '#S')

    if [[ "$current" == "$base" ]]; then
        return 0
    fi

    if ! tmux has-session -t "$base" 2>/dev/null; then
        tmux new-session -ds "$base"
    fi

    tmux switch-client -t "$base"
    tmux kill-session -t "$current"
}

# =============================================================================
# MAIN ENTRY POINT
# =============================================================================

pj() {
    case "$1" in
        clone) shift; _pj_clone "$@" ;;
        close) _pj_close ;;
        "")    _pj_pick ;;
        *)     print -r "Usage: pj [clone <url> | close]" >&2; return 1 ;;
    esac
}
