#!/bin/zsh
# save-workspace.sh — Upsert a workspace entry in dk.yaml
# Usage: save-workspace.sh <key> <description> <dir1,dir2,...> <common_root> <session_name> <kind>
set -euo pipefail

KEY="${1:?}"
DESC="${2:?}"
DIRS_CSV="${3:?}"
COMMON_ROOT="${4:?}"
SESSION_NAME="${5:?}"
KIND="${6:-convention}"

CACHE="$HOME/Code/dk-digital-bank/dk.yaml"
[[ -f "$CACHE" ]] || { echo "Cache not found: $CACHE" >&2; exit 1; }

# Remove from discovered if present
yq e "del(.discovered.\"$KEY\")" -i "$CACHE"

# Convert CSV to YAML array
dirs_yaml=$(echo "$DIRS_CSV" | tr ',' '\n' | sed 's/^/        - /')

# Upsert workspace entry
yq e ".workspaces.\"$KEY\".description = \"$DESC\"" -i "$CACHE"
yq e ".workspaces.\"$KEY\".common_root = \"$COMMON_ROOT\"" -i "$CACHE"
yq e ".workspaces.\"$KEY\".session_name = \"$SESSION_NAME\"" -i "$CACHE"
yq e ".workspaces.\"$KEY\".kind = \"$KIND\"" -i "$CACHE"
yq e ".workspaces.\"$KEY\".last_opened = \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"" -i "$CACHE"

# Set dirs (requires building the array)
yq e ".workspaces.\"$KEY\".dirs = []" -i "$CACHE"
while IFS=',' read -rA dirs; do
  for d in "${dirs[@]}"; do
    [[ -n "$d" ]] || continue
    yq e ".workspaces.\"$KEY\".dirs += [\"$d\"]" -i "$CACHE"
  done
done <<< "$DIRS_CSV"

echo "Saved workspace: $KEY"
