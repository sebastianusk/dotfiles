#!/bin/bash
# notify-with-focus.sh
# Called by opencode-notifier when events fire.
# Sends a terminal-notifier notification that, when clicked,
# brings the user back to Alacritty + the correct tmux session/window.
#
# Args: $1 = event type, $2 = message

set -euo pipefail

EVENT="${1:-unknown}"
MSG="${2:-OpenCode event}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/opencode-notifier"

umask 077
mkdir -p "$STATE_DIR"
STATE_FILE="$(mktemp "$STATE_DIR/focus.XXXXXX")"
find "$STATE_DIR" -type f -name 'focus.*' -mtime +7 -delete

# Detect if running inside tmux and capture context
if [ -n "${TMUX:-}" ]; then
  TMUX_SESSION=$(tmux display-message -p '#{session_name}')
  TMUX_WINDOW=$(tmux display-message -p '#{window_index}')
  TMUX_PANE=$(tmux display-message -p '#{pane_index}')
  # Get the tmux client name for precise switching
  TMUX_CLIENT=$(tmux list-clients -F '#{client_name}' | head -1)
  printf 'TMUX_SESSION=%s\nTMUX_WINDOW=%s\nTMUX_PANE=%s\nTMUX_CLIENT=%s\n' \
    "$TMUX_SESSION" "$TMUX_WINDOW" "$TMUX_PANE" "$TMUX_CLIENT" > "$STATE_FILE"
else
  # Not in tmux — just save that we're in Alacritty
  printf 'TMUX_SESSION=\nTMUX_WINDOW=\nTMUX_PANE=\nTMUX_CLIENT=\n' > "$STATE_FILE"
fi

# Pick notification title based on event
case "$EVENT" in
  permission)   TITLE="OpenCode — Permission Needed" ;;
  complete)     TITLE="OpenCode — Done" ;;
  subagent_complete) TITLE="OpenCode — Subagent Done" ;;
  error)        TITLE="OpenCode — Error" ;;
  question)     TITLE="OpenCode — Question" ;;
  plan_exit)    TITLE="OpenCode — Plan Ready" ;;
  *)            TITLE="OpenCode — ${EVENT}" ;;
esac

# Send notification via terminal-notifier (click-to-focus via -execute)
if command -v terminal-notifier >/dev/null 2>&1; then
  terminal-notifier \
    -title "$TITLE" \
    -message "$MSG" \
    -sound "default" \
    -group "opencode" \
    -execute "$SCRIPT_DIR/focus-opencode.sh $STATE_FILE"
else
  # Fallback to osascript if terminal-notifier is not installed
  osascript - "$TITLE" "$MSG" <<'APPLESCRIPT'
on run argv
  display notification (item 2 of argv) with title (item 1 of argv) sound name "default"
end run
APPLESCRIPT
fi
