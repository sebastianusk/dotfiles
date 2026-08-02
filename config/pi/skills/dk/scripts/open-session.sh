#!/bin/zsh
# open-session.sh — Open a tmux session for a dk workspace
# Usage: open-session.sh <workspace-name>
set -euo pipefail

WS_NAME="${1:?Usage: open-session.sh <workspace-name>}"
CACHE="$HOME/Code/dk-digital-bank/dk.yaml"
CODE_ROOT="$HOME/Code/dk-digital-bank"

[[ -f "$CACHE" ]] || { echo "Cache not found: $CACHE" >&2; exit 1; }

session_name=$(yq e ".workspaces.\"$WS_NAME\".session_name // \"\"" "$CACHE")
common_root=$(yq e ".workspaces.\"$WS_NAME\".common_root // \"\"" "$CACHE")

[[ -n "$session_name" ]] || { echo "Session name not found for workspace: $WS_NAME" >&2; exit 1; }

# Kill existing session with same name
tmux kill-session -t "$session_name" 2>/dev/null || true

# Start new session via tmuxinator
(cd "$CODE_ROOT/$common_root" && tmuxinator start dev -n "$session_name" -p ~/.tmuxinator/dev.yml)

# Attach
if [[ -n "${TMUX:-}" ]]; then
  tmux switch-client -t "$session_name"
else
  tmux attach -t "$session_name"
fi
