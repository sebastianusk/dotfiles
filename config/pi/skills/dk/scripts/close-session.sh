#!/bin/zsh
# close-session.sh — Close the current dk tmux session and switch to base
set -euo pipefail

current=$(tmux display-message -p '#S' 2>/dev/null) || {
  echo "Not in a tmux session" >&2
  exit 1
}

if [[ "$current" != "0" ]]; then
  tmux has-session -t 0 2>/dev/null || tmux new-session -ds 0
  tmux switch-client -t 0
  tmux kill-session -t "$current"
  echo "Closed session: $current"
else
  echo "Already on base session (0), not closing"
fi
