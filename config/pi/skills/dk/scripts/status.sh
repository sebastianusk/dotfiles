#!/bin/zsh
# status.sh — Show dirty repos across all dk workspaces
# Usage: status.sh [workspace-name]  (omit arg to check all)
set -euo pipefail

CACHE="$HOME/Code/dk-digital-bank/dk.yaml"
CODE_ROOT="$HOME/Code/dk-digital-bank"

[[ -f "$CACHE" ]] || { echo "Cache not found: $CACHE" >&2; exit 1; }

WS_FILTER="${1:-}"

workspaces=$(yq e '.workspaces | keys | .[]' "$CACHE" 2>/dev/null) || exit 0

found=0
while IFS= read -r ws; do
  [[ -n "$ws" ]] || continue
  [[ -z "$WS_FILTER" || "$ws" == "$WS_FILTER" ]] || continue

  dirs=$(yq e ".workspaces.\"$ws\".dirs | .[]" "$CACHE" 2>/dev/null) || continue
  while IFS= read -r dir; do
    [[ -n "$dir" ]] || continue
    dirty=$(git -C "$CODE_ROOT/$dir" status --porcelain 2>/dev/null) || continue
    if [[ -n "$dirty" ]]; then
      count=$(echo "$dirty" | wc -l | xargs)
      echo "  * $ws: $dir — $count files"
      found=1
    fi
  done <<< "$dirs"
done <<< "$workspaces"

if [[ $found -eq 0 ]]; then
  echo "All clean."
fi
