#!/usr/bin/env bash
# confluence.sh — Confluence Cloud page manager
# Requires: curl, jq, and env vars ATLASSIAN_DOMAIN, ATLASSIAN_EMAIL, ATLASSIAN_API_TOKEN.
set -euo pipefail

CACHE_DIR="${HOME}/.cache/confluence"
SPACES_CACHE="${CACHE_DIR}/spaces.json"
BASE_PATH="/wiki/api/v2"

# ---------------------------------------------------------------------------
# helpers
# ---------------------------------------------------------------------------

require_env() {
  local missing=()
  [ -n "${ATLASSIAN_DOMAIN:-}" ]     || missing+=("ATLASSIAN_DOMAIN")
  [ -n "${ATLASSIAN_EMAIL:-}" ]      || missing+=("ATLASSIAN_EMAIL")
  [ -n "${ATLASSIAN_API_TOKEN:-}" ]  || missing+=("ATLASSIAN_API_TOKEN")
  if [ "${#missing[@]}" -gt 0 ]; then
    echo "ERROR: missing env var(s): ${missing[*]}" >&2
    echo "Export them in your shell:" >&2
    local m
    for m in "${missing[@]}"; do echo "  export $m=..." >&2; done
    echo "ATLASSIAN_DOMAIN = '<you>.atlassian.net', ATLASSIAN_EMAIL = your Atlassian email, ATLASSIAN_API_TOKEN = Cloud token." >&2
    exit 1
  fi
}

auth_header() {
  printf 'Basic %s' "$(printf '%s:%s' "$ATLASSIAN_EMAIL" "$ATLASSIAN_API_TOKEN" | base64 | tr -d '\n')"
}

api() {
  # api <method> <path> [json-file-or--]
  local method="$1" path="$2" data="${3:-}"
  local args=( -sS -w '\n%{http_code}' )
  args+=( -H "Authorization: $(auth_header)" -H "Accept: application/json" )
  [ "$method" != "GET" ] && args+=( -X "$method" )
  if [ -n "$data" ] && [ "$data" != "-" ] && [ -f "$data" ]; then
    args+=( -H "Content-Type: application/json" --data "@$data" )
  elif [ "$data" = "-" ]; then
    args+=( -H "Content-Type: application/json" --data @- )
  fi
  local out
  out="$(curl "${args[@]}" --max-time 30 "https://${ATLASSIAN_DOMAIN}${path}")" || {
    echo "ERROR: curl failed (network?)" >&2; exit 1; }
  local code body
  code="$(printf '%s' "$out" | tail -n1)"
  body="$(printf '%s' "$out" | sed '$d')"
  if [ "$code" -ge 400 ]; then
    echo "ERROR: HTTP $code from $method $path" >&2
    printf '%s' "$body" | jq -r '.message // .errorMessages[]? // empty' 2>/dev/null >&2 || printf '%s\n' "$body" >&2
    exit 1
  fi
  printf '%s' "$body"
}

# Fetch all spaces via paginated v2 API (cursor-based). Writes a JSON array to stdout.
# Caps at max_pages to prevent infinite loops on a stuck cursor.
fetch_all_spaces() {
  local cursor="" body page=0 max_pages=50
  local tmp
  tmp="$(mktemp)"
  while [ "$page" -lt "$max_pages" ]; do
    page=$((page+1))
    if [ -z "$cursor" ]; then
      body="$(api GET "${BASE_PATH}/spaces?limit=250")"
    else
      body="$(api GET "${cursor}")"
    fi
    printf '%s' "$body" | jq -c '.results[] | {id,key,name}' >> "$tmp"
    cursor="$(printf '%s' "$body" | jq -r '._links.next // empty')"
    [ -z "$cursor" ] && break
  done
  if [ "$page" -ge "$max_pages" ]; then
    echo "WARN: hit max_pages=$max_pages cap; space cache may be incomplete" >&2
  fi
  jq -s '.' "$tmp"
  rm -f "$tmp"
}

# Resolve space key to space id. Caches space list.
space_id() {
  local key="$1"
  mkdir -p "$CACHE_DIR"
  if [ ! -f "$SPACES_CACHE" ]; then
    fetch_all_spaces > "$SPACES_CACHE"
  fi
  local id
  id="$(jq -r --arg k "$key" '.[] | select(.key == $k) | .id' "$SPACES_CACHE")"
  if [ -z "$id" ] || [ "$id" = "null" ]; then
    echo "ERROR: space key '$key' not found (cached). Run 'auth-test' to refresh." >&2
    exit 1
  fi
  printf '%s' "$id"
}

sti_storage() {
  # Convert a plain string to storage-format body payload.
  # Usage: sti_storage "content" => JSON object with representation and value.
  local text="$1"
  printf '{"representation":"storage","value":"%s"}' "$(printf '%s' "$text" | sed 's/"/\\"/g')"
}

# ---------------------------------------------------------------------------
# subcommands
# ---------------------------------------------------------------------------

fn_auth_test() {
  mkdir -p "$CACHE_DIR"
  fetch_all_spaces > "$SPACES_CACHE"
  local count
  count="$(jq 'length' "$SPACES_CACHE")"
  echo "OK: authenticated, ${count} spaces available"
  echo "Cached to $SPACES_CACHE"
}

fn_spaces() {
  if [ ! -f "$SPACES_CACHE" ]; then
    fn_auth_test >/dev/null
  fi
  jq -r '.[] | "\(.key)\t\(.name)\t\(.id)"' "$SPACES_CACHE" | column -t -s $'\t'
}

fn_pages() {
  # List pages in a space.
  local space_key="" title="" limit=50
  while [ $# -gt 0 ]; do
    case "$1" in
      --space)  space_key="$2"; shift 2;;
      --title)  title="$2";   shift 2;;
      --limit)  limit="$2";   shift 2;;
      *) echo "pages: unknown arg: $1" >&2; exit 1;;
    esac
  done
  if [ -z "$space_key" ]; then echo "pages: --space <KEY> is required" >&2; exit 1; fi
  local sid
  sid="$(space_id "$space_key")"
  local qp="limit=${limit}&sort=-modified-date"
  [ -n "$title" ] && qp="${qp}&title=$(printf '%s' "$title" | jq -sRr @uri)"
  local resp
  resp="$(api GET "${BASE_PATH}/spaces/${sid}/pages?${qp}")"
  printf '%s' "$resp" | jq -r \
    '.results[] | "\(.id)\t\(.title)\t\(.status)\t\(.version.number)\t\(.createdAt)"' \
    | column -t -s $'\t'
}

# Convert storage-format HTML to plain text suitable for agent consumption.
storage_to_plain() {
  sed -E \
    -e 's/&rsquo;/'"'"'/g' \
    -e 's/&lsquo;/'"'"'/g' \
    -e 's/&rdquo;/"/g' \
    -e 's/&ldquo;/"/g' \
    -e 's/&amp;/\&/g' \
    -e 's/&lt;/</g' \
    -e 's/&gt;/>/g' \
    -e 's/&nbsp;/ /g' \
    -e 's/&#39;/'"'"'/g' \
    -e 's|<li[^>]*><p[^>]*>|<li>|g' \
    -e 's|</p></li>|</li>|g' \
    -e '/<ac:structured-macro[^>]*ac:name="code"/,/ac:structured-macro/{
      s|<ac:plain-text-body><!\[CDATA\[||g
      s|\]\]></ac:plain-text-body>||g
    }' \
    -e 's|<ac:structured-macro[^>]*ac:name="jira"[^>]*>||g' \
    -e 's|</ac:structured-macro>||g' \
    -e 's|<ac:parameter[^>]*ac:name="key">([^<]*)</ac:parameter>|[Jira: \1]|g' \
    -e 's|<ac:parameter[^>]*>[^<]*</ac:parameter>||g' \
    -e 's|<ac:link><ri:page[^>]*ri:content-title="([^"]*)"[^>]*/>[^<]*</ac:link>|[Page: \1]|g' \
    -e 's|<ri:page[^>]*ri:content-title="([^"]*)"[^>]*/>|[Page: \1]|g' \
    -e 's|<ac:link-body>[^<]*</ac:link-body>||g' \
    -e 's|<ac:link[^>]*>||g' \
    -e 's|</ac:link>||g' \
    -e 's|<a[^>]*href="([^"]*)"[^>]*>| [Link: \1]|g' \
    -e 's|</a>||g' \
    -e 's|<ac:plain-text-body>||g' \
    -e 's|</ac:plain-text-body>||g' \
    -e 's|<h1[^>]*>|\n# |g' \
    -e 's|<h2[^>]*>|\n## |g' \
    -e 's|<h3[^>]*>|\n### |g' \
    -e 's|<h4[^>]*>|\n#### |g' \
    -e 's|<h5[^>]*>|\n##### |g' \
    -e 's|<h6[^>]*>|\n###### |g' \
    -e 's|</h[1-6]>||g' \
    -e 's|<p[^>]*>|\n\n|g' \
    -e 's|</p>||g' \
    -e 's|<li[^>]*>|\n- |g' \
    -e 's|</li>||g' \
    -e 's|</?ul>||g' \
    -e 's|</?ol>||g' \
    -e 's|<br[^>]*>||g' \
    -e 's|<code[^>]*>|`|g' \
    -e 's|</code>|`|g' \
    -e 's|<strong[^>]*>|**|g' \
    -e 's|</strong>|**|g' \
    -e 's|<em[^>]*>|*|g' \
    -e 's|</em>|*|g' \
    -e 's|<[^>]*>||g' \
    -e 's/^[[:space:]]+//' \
    -e 's/[[:space:]]+$//' \
    -e '/^$/{ N; /^\n$/D; }'
}

fn_get() {
  local id="" fmt="storage" plain=false
  while [ $# -gt 0 ]; do
    case "$1" in
      --format) fmt="$2"; shift 2;;
      --plain)  plain=true; shift;;
      -*) echo "get: unknown arg: $1" >&2; exit 1;;
      *) id="$1"; shift;;
    esac
  done
  if [ -z "$id" ]; then echo "get: <PAGE-ID> is required" >&2; exit 1; fi

  # Get page metadata
  local meta
  meta="$(api GET "${BASE_PATH}/pages/${id}?body-format=${fmt}")"

  local body_val
  body_val="$(printf '%s' "$meta" | jq -r '(.body.storage.value // .body.atlas_doc_format.value // "(empty)")')"
  if [ "$plain" = true ]; then
    body_val="$(printf '%s' "$body_val" | storage_to_plain)"
  fi

  printf '%s' "$meta" | jq -r \
    --arg body "$body_val" \
    '
    "Page ID:      \(.id)",
    "Title:        \(.title)",
    "Space:        \(.spaceId)",
    "Status:       \(.status)",
    "Version:      \(.version.number)",
    "Author:       \(.version.authorId // .authorId // "-")",
    "Created:      \(.createdAt)",
    "Parent:       \(.parentId // "(root)")",
    "",
    "Body:",
    $body'

  # Fetch children
  local children
  children="$(api GET "${BASE_PATH}/pages/${id}/children?limit=50")"
  local child_count
  child_count="$(printf '%s' "$children" | jq '.results | length')"
  if [ "$child_count" -gt 0 ]; then
    printf '\nChildren (%s):\n' "$child_count"
    printf '%s' "$children" | jq -r '.results[] | "  \(.id)  \(.title)"'
  fi
}

fn_search() {
  local query="${1:-}" space_key="" limit=20
  shift 2>/dev/null || true
  while [ $# -gt 0 ]; do
    case "$1" in
      --space)  space_key="$2"; shift 2;;
      --limit)  limit="$2";   shift 2;;
      *) echo "search: unknown arg: $1" >&2; exit 1;;
    esac
  done
  if [ -z "$query" ]; then echo "search: <query> is required" >&2; exit 1; fi

  # Use REST API /search for text search (v2 search is limited)
  local cql="type=page AND text~\"$(printf '%s' "$query" | sed 's/"/\\"/g')\""
  [ -n "$space_key" ] && cql="${cql} AND space=\"${space_key}\""
  local encoded_cql
  encoded_cql="$(printf '%s' "$cql" | jq -sRr @uri)"
  local resp
  resp="$(api GET "/wiki/rest/api/search?cql=${encoded_cql}&limit=${limit}")"
  printf '%s' "$resp" | jq -r \
    '.results[] | "\(.content.id)\t\(.content.title)\t\("\(.content._links.webui // .url)" | split("/")[2])\t\(.friendlyLastModified // .lastModified)"' \
    | column -t -s $'\t'
}

fn_create() {
  local title="" space_key="" body="" parent_id=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --title)  title="$2";     shift 2;;
      --space)  space_key="$2"; shift 2;;
      --body)   body="$2";      shift 2;;
      --parent) parent_id="$2";  shift 2;;
      *) echo "create: unknown arg: $1" >&2; exit 1;;
    esac
  done
  if [ -z "$title" ]; then echo "create: --title is required" >&2; exit 1; fi
  if [ -z "$space_key" ]; then echo "create: --space <KEY> is required" >&2; exit 1; fi
  if [ -z "$body" ]; then echo "create: --body is required" >&2; exit 1; fi

  local sid
  sid="$(space_id "$space_key")"

  local body_obj
  body_obj="$(sti_storage "$body")"

  local payload
  payload="$(jq -nc \
    --arg sid "$sid" --arg title "$title" --argjson b "$body_obj" --arg pid "$parent_id" \
    '{spaceId:$sid,status:"current",title:$title,body:$b} + (if $pid != "" then {parentId:$pid} else {} end)')"
  local resp
  resp="$(printf '%s' "$payload" | api POST "${BASE_PATH}/pages" -)"
  local id title_out
  id="$(printf '%s' "$resp" | jq -r '.id')"
  title_out="$(printf '%s' "$resp" | jq -r '.title')"
  echo "Created page: $id — $title_out"
  echo "https://${ATLASSIAN_DOMAIN}/wiki/spaces/${space_key}/pages/${id}"
}

fn_update() {
  local id="" title="" body="" version=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --title)   title="$2";   shift 2;;
      --body)    body="$2";    shift 2;;
      --version) version="$2"; shift 2;;
      -*) echo "update: unknown arg: $1" >&2; exit 1;;
      *) id="$1"; shift;;
    esac
  done
  if [ -z "$id" ]; then echo "update: <PAGE-ID> is required" >&2; exit 1; fi

  # Fetch current page if version not provided
  if [ -z "$version" ]; then
    local current
    current="$(api GET "${BASE_PATH}/pages/${id}")"
    version="$(printf '%s' "$current" | jq -r '.version.number')"
    if [ -z "$title" ]; then title="$(printf '%s' "$current" | jq -r '.title')"; fi
  fi
  local new_ver=$((version + 1))

  local space_id
  space_id="$(printf '%s' "$current" | jq -r '.spaceId')"

  local body_part="null"
  if [ -n "$body" ]; then
    body_part="$(sti_storage "$body")"
  fi

  local payload
  payload="$(jq -nc \
    --arg id "$id" --arg title "$title" --argjson b "$body_part" \
    --argjson v "$new_ver" --arg sid "$space_id" \
    '{id:$id,status:"current",title:$title,spaceId:$sid,version:{number:$v,message:""}} + (if $b != null then {body:$b} else {} end)')"
  local resp
  resp="$(printf '%s' "$payload" | api PUT "${BASE_PATH}/pages/${id}" -)"
  echo "Updated page: $(printf '%s' "$resp" | jq -r '.id') — $(printf '%s' "$resp" | jq -r '.title') (v$new_ver)"
}

fn_delete() {
  local id="${1:-}" force=false
  shift 2>/dev/null || true
  while [ $# -gt 0 ]; do
    case "$1" in
      --force) force=true; shift;;
      *) echo "delete: unknown arg: $1" >&2; exit 1;;
    esac
  done
  if [ -z "$id" ]; then echo "delete: <PAGE-ID> is required" >&2; exit 1; fi
  if [ "$force" = false ]; then
    echo "delete: refusing to delete ${id} without --force" >&2; exit 1
  fi
  api DELETE "${BASE_PATH}/pages/${id}" >/dev/null
  echo "Deleted page ${id}"
}

fn_open() {
  local id="${1:-}"
  if [ -z "$id" ]; then echo "open: <PAGE-ID> is required" >&2; exit 1; fi
  # need to fetch page to get space key
  local page
  page="$(api GET "${BASE_PATH}/pages/${id}")"
  local space_key
  space_key="$(printf '%s' "$page" | jq -r '.spaceId')"
  # Resolve space key from id if possible, otherwise use id
  if [ -f "$SPACES_CACHE" ]; then
    local sk
    sk="$(jq -r --arg id "$space_key" '.[] | select(.id == $id) | .key' "$SPACES_CACHE")"
    [ -n "$sk" ] && [ "$sk" != "null" ] && space_key="$sk"
  fi
  open "https://${ATLASSIAN_DOMAIN}/wiki/spaces/${space_key}/pages/${id}"
}

usage() {
  cat <<'EOF'
confluence.sh — Confluence Cloud page manager

usage: confluence.sh <subcommand> [opts]

  auth-test                    Verify credentials; cache space list
  spaces                       List all spaces
  pages    --space KEY         List pages in a space
           [--title TITLE] [--limit N]
  get      <PAGE-ID>           Get page metadata, body, and children
           [--format storage|atlas_doc_format]
  search   <query>             Search pages by text
           [--space KEY] [--limit N]
  create   --title "Title" --space KEY --body "storage html"
           [--parent PARENT-ID]
  update   <PAGE-ID>           Update page title/body
           [--title "New"] [--body "html"] [--version N]
  delete   <PAGE-ID> --force   Delete a page
  open     <PAGE-ID>           Open page in browser

Env: ATLASSIAN_DOMAIN, ATLASSIAN_EMAIL, ATLASSIAN_API_TOKEN
EOF
}

# ---------------------------------------------------------------------------
# dispatch
# ---------------------------------------------------------------------------

require_env
[ $# -eq 0 ] && { usage; exit 0; }
case "${1:-}" in
  -h|--help) usage;;
  auth-test) shift; fn_auth_test "$@";;
  spaces)    shift; fn_spaces "$@";;
  pages)     shift; fn_pages "$@";;
  get)       shift; fn_get "$@";;
  search)    shift; fn_search "$@";;
  create)    shift; fn_create "$@";;
  update)    shift; fn_update "$@";;
  delete)    shift; fn_delete "$@";;
  open)      shift; fn_open "$@";;
  *) echo "Unknown subcommand: $1" >&2; usage >&2; exit 1;;
esac
