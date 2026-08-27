#!/usr/bin/env bash
# jira.sh — Jira Cloud ticket manager
# Requires: curl, jq, and env vars ATLASSIAN_DOMAIN, ATLASSIAN_EMAIL, ATLASSIAN_API_TOKEN.
set -euo pipefail

CACHE_DIR="${HOME}/.cache/jira"
MYSELF_CACHE="${CACHE_DIR}/myself.json"

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
    printf '%s' "$body" | jq -r '.errorMessages[]?, .errors | if type=="object" then to_entries[] | "\(.key): \(.value)" else empty end' 2>/dev/null >&2 || printf '%s\n' "$body" >&2
    exit 1
  fi
  printf '%s' "$body"
}

ensure_myself() {
  if [ ! -f "$MYSELF_CACHE" ]; then
    fn_auth_test >/dev/null
  fi
}

self_account_id() {
  ensure_myself
  jq -r '.accountId' "$MYSELF_CACHE"
}

# Build ADF document with a single paragraph containing one text node.
# Usage: adf_text "some text"
adf_text() {
  local text="$1"
  jq -nc --arg t "$text" '{type:"doc",version:1,content:[{type:"paragraph",content:[{type:"text",text:$t}]}]}'
}

# ---------------------------------------------------------------------------
# subcommands
# ---------------------------------------------------------------------------

fn_auth_test() {
  local body
  body="$(api GET /rest/api/3/myself)"
  local name email aid
  name="$(printf '%s' "$body" | jq -r '.displayName')"
  email="$(printf '%s' "$body" | jq -r '.emailAddress')"
  aid="$(printf '%s' "$body" | jq -r '.accountId')"
  mkdir -p "$CACHE_DIR"
  printf '%s' "$body" | jq '{accountId,displayName,emailAddress}' > "$MYSELF_CACHE"
  echo "OK: $name <$email> (accountId=$aid)"
  echo "Cached to $MYSELF_CACHE"
}

fn_create() {
  local summary="" desc="" type="Story" project="DX" assignee="" no_assign=false parent="" epic_link=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --summary)   summary="$2";    shift 2;;
      --desc)      desc="$2";       shift 2;;
      --type)      type="$2";       shift 2;;
      --project)   project="$2";    shift 2;;
      --assignee)  assignee="$2"; no_assign=false; shift 2;;
      --no-assign) no_assign=true;   shift;;
      --parent)    parent="$2";      shift 2;;
      --epic-link) epic_link="$2";    shift 2;;
      *) echo "create: unknown arg: $1" >&2; exit 1;;
    esac
  done
  if [ -z "$summary" ]; then echo "create: --summary is required" >&2; exit 1; fi

  local assignee_obj="null"
  if [ "$no_assign" = false ]; then
    local aid="$assignee"
    [ -n "$aid" ] || aid="$(self_account_id)"
    assignee_obj="$(jq -nc --arg a "$aid" '{accountId:$a}')"
  fi

  local desc_obj="null"
  if [ -n "$desc" ]; then
    desc_obj="$(adf_text "$desc")"
  fi

  local parent_obj="null"
  if [ -n "$parent" ]; then
    parent_obj="$(jq -nc --arg k "$parent" '{key:$k}')"
  fi

  local epic_obj="null"
  if [ -n "$epic_link" ]; then
    epic_obj="$(jq -nc --arg e "$epic_link" '"\($e)"')"
  fi

  local body
  body="$(jq -nc \
    --arg p "$project" --arg s "$summary" --arg t "$type" \
    --argjson d "$desc_obj" --argjson a "$assignee_obj" \
    --argjson parent "$parent_obj" \
    --argjson epic "$epic_obj" \
    --argjson labels '["dxt","DXT"]' \
    '{fields:{project:{key:$p},summary:$s,description:$d,issuetype:{name:$t},labels:$labels}} * (if $a != null then {fields:{assignee:$a}} else {} end) * (if $parent != null then {fields:{parent:$parent}} else {} end) * (if $epic != null then {fields:{customfield_10014:$epic}} else {} end)')"
  local resp
  resp="$(printf '%s' "$body" | api POST /rest/api/3/issue -)"
  local key
  key="$(printf '%s' "$resp" | jq -r '.key')"
  echo "$key"
  echo "https://${ATLASSIAN_DOMAIN}/browse/${key}"
}

fn_mine() {
  local project="" show_all=false
  while [ $# -gt 0 ]; do
    case "$1" in
      --project) project="$2"; shift 2;;
      --all) show_all=true; shift;;
      *) echo "mine: unknown arg: $1" >&2; exit 1;;
    esac
  done
  local jql="assignee = currentUser()"
  [ -n "$project" ] && jql="${jql} AND project = ${project}"
  [ "$show_all" = false ] && jql="${jql} AND statusCategory != Done"
  jql="${jql} ORDER BY updated DESC"
  local body
  body="$(jq -nc --arg j "$jql" '{jql:$j,fields:["summary","status","issuetype","priority","updated"],maxResults:100}')"
  local resp
  resp="$(printf '%s' "$body" | api POST /rest/api/3/search/jql -)"
  printf '%s' "$resp" | jq -r \
    '.issues[] | "\(.key)\t\(.fields.status.name)\t\(.fields.issuetype.name)\t\(.fields.summary)"' \
    | column -t -s $'\t'
}

fn_detail() {
  local key="" with_comments=false
  while [ $# -gt 0 ]; do
    case "$1" in
      --comments) with_comments=true; shift;;
      -*) echo "detail: unknown arg: $1" >&2; exit 1;;
      *) key="$1"; shift;;
    esac
  done
  if [ -z "$key" ]; then echo "detail: <KEY> is required" >&2; exit 1; fi
  local resp
  local fields="summary,status,issuetype,priority,assignee,reporter,created,updated,labels,components,description,comment"
  resp="$(api GET "/rest/api/3/issue/${key}?fields=${fields}")"
  printf '%s' "$resp" | jq -r '
    def adf: [.. | .text? // empty] | join("\n");
    "Key:          \(.key)",
    "Summary:      \(.fields.summary)",
    "Status:       \(.fields.status.name)",
    "Type:         \(.fields.issuetype.name)",
    "Priority:     \(.fields.priority.name // "-")",
    "Assignee:     \(.fields.assignee.displayName // "Unassigned")",
    "Reporter:     \(.fields.reporter.displayName // "-")",
    "Created:      \(.fields.created)",
    "Updated:      \(.fields.updated)",
    "Labels:       \(.fields.labels | if length > 0 then join(", ") else "-" end)",
    "Components:   \(.fields.components | if length > 0 then map(.name) | join(", ") else "-" end)",
    "Description:",
    (.fields.description | if . then adf else "(empty)" end)'
  if [ "$with_comments" = true ]; then
    printf '%s' "$resp" | jq -r --arg adf adf '
      .fields.comment.comments | if length == 0 then "\nComments: (none)" else
        "\nComments:",
        (.[] | "\(.created) — \(.author.displayName):\n  (\(.body | [.. | .text? // empty] | join("\n")))")
      end'
  fi
}

fn_open() {
  local key="${1:-}"
  if [ -z "$key" ]; then echo "open: <KEY> is required" >&2; exit 1; fi
  open "https://${ATLASSIAN_DOMAIN}/browse/${key}"
}

fn_comment() {
  local key="${1:-}" text="${2:-}"
  if [ -z "$key" ] || [ -z "$text" ]; then
    echo "comment: usage: jira.sh comment <KEY> \"text\"" >&2; exit 1
  fi
  local body
  body="$(jq -nc --argjson adf "$(adf_text "$text")" '{body:$adf}')"
  printf '%s' "$body" | api POST "/rest/api/3/issue/${key}/comment" - >/dev/null
  echo "Comment added to ${key}"
}

fn_transition() {
  local key="${1:-}" state="${2:-}"
  if [ -z "$key" ] || [ -z "$state" ]; then
    echo "transition: usage: jira.sh transition <KEY> \"state\"" >&2; exit 1
  fi
  local resp tid
  resp="$(api GET "/rest/api/3/issue/${key}/transitions")"
  tid="$(printf '%s' "$resp" | jq -r --arg s "$state" '
    .transitions | map(. + {l: (.name | ascii_downcase)}) | first(.[] | select(.l | contains($s | ascii_downcase))) | .id')"
  if [ -z "$tid" ] || [ "$tid" = "null" ]; then
    echo "transition: no matching state for \"$state\" on ${key}." >&2
    printf '%s' "$resp" | jq -r '.transitions[] | "  - \(.name)"' >&2
    exit 1
  fi
  local body
  body="$(jq -nc --arg id "$tid" '{transition:{id:$id}}')"
  printf '%s' "$body" | api POST "/rest/api/3/issue/${key}/transitions" - >/dev/null
  echo "Transitioned ${key} to matched state (id=$tid)."
}

fn_delete() {
  local key="${1:-}" force=false
  shift 2>/dev/null || true
  while [ $# -gt 0 ]; do
    case "$1" in
      --force) force=true; shift;;
      *) echo "delete: unknown arg: $1" >&2; exit 1;;
    esac
  done
  if [ -z "$key" ]; then echo "delete: <KEY> is required" >&2; exit 1; fi
  if [ "$force" = false ]; then
    echo "delete: refusing to delete ${key} without --force" >&2; exit 1
  fi
  api DELETE "/rest/api/3/issue/${key}?deleteSubtasks=true" >/dev/null
  echo "Deleted ${key}"
}

usage() {
  cat <<'EOF'
jira.sh — Jira Cloud ticket manager

usage: jira.sh <subcommand> [opts]

  auth-test                         Verify credentials; cache account info
  create    --summary "Title"       Create ticket (project DX, type Story, self-assign)
            [--desc "..."] [--type TYPE] [--project KEY] [--no-assign]
            [--parent KEY] [--epic-link KEY]
  mine      [--project KEY] [--all] List tickets assigned to you
  detail    <KEY> [--comments]      Show ticket detail (+ comments)
  open      <KEY>                   Open ticket in browser
  comment   <KEY> "text"            Add a comment
  transition <KEY> "state"          Transition state (partial match ok)
  delete    <KEY> --force           Delete a ticket (+ subtasks)

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
  create)    shift; fn_create "$@";;
  mine)      shift; fn_mine "$@";;
  detail)    shift; fn_detail "$@";;
  open)      shift; fn_open "$@";;
  comment)   shift; fn_comment "$@";;
  transition) shift; fn_transition "$@";;
  delete)    shift; fn_delete "$@";;
  *) echo "Unknown subcommand: $1" >&2; usage >&2; exit 1;;
esac
