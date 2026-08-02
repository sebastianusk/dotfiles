#!/bin/zsh
# pull-workspace.sh — Pull (or clone) all repos for a dk workspace
# Usage: pull-workspace.sh <workspace-name>
set -euo pipefail

WS_NAME="${1:?Usage: pull-workspace.sh <workspace-name>}"
CACHE="$HOME/Code/dk-digital-bank/dk.yaml"
CODE_ROOT="$HOME/Code/dk-digital-bank"

[[ -f "$CACHE" ]] || { echo "Cache not found: $CACHE" >&2; exit 1; }

dirs=$(yq e ".workspaces.\"$WS_NAME\".dirs | .[]" "$CACHE" 2>/dev/null) || {
  echo "Workspace not found in cache: $WS_NAME" >&2
  exit 1
}

while IFS= read -r dir; do
  [[ -n "$dir" ]] || continue
  target="$CODE_ROOT/$dir"
  if [[ -d "$target/.git" ]]; then
    echo "=== Pulling $dir ==="
    git -C "$target" pull --ff-only
  else
    echo "=== Cloning $dir ==="
    mkdir -p "$(dirname "$target")"
    glab repo clone "dk-digital-bank/$dir" "$target"
  fi
done <<< "$dirs"

echo "Done."
