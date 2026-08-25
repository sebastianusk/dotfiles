#!/bin/bash
# focus-opencode.sh
# Called when the user clicks the terminal-notifier notification.
# Brings Alacritty to front and switches tmux to the saved session/window.

set -euo pipefail

STATE_FILE="${1:-}"

# Load saved state
TMUX_SESSION=""
TMUX_WINDOW=""
TMUX_PANE=""
TMUX_CLIENT=""
ALACRITTY_BUNDLE="org.alacritty"

if [[ -n "$STATE_FILE" && -f "$STATE_FILE" && ! -L "$STATE_FILE" ]]; then
  while IFS='=' read -r key value; do
    case "$key" in
      TMUX_SESSION) TMUX_SESSION="$value" ;;
      TMUX_WINDOW) TMUX_WINDOW="$value" ;;
      TMUX_PANE) TMUX_PANE="$value" ;;
      TMUX_CLIENT) TMUX_CLIENT="$value" ;;
    esac
  done < "$STATE_FILE"
fi

# Activate Alacritty
osascript -e "tell application \"System Events\"" \
          -e "  set frontApp to first application process whose bundle identifier is \"$ALACRITTY_BUNDLE\"" \
          -e "  set frontmost of frontApp to true" \
          -e "end tell"

# If we have tmux context, switch to the correct session/window
if [ -n "${TMUX_SESSION:-}" ] && [ -n "${TMUX_WINDOW:-}" ]; then
  # Wait a tiny bit for Alacritty to actually be frontmost (helps focus)
  sleep 0.2

  # Switch the client to the right session and window
  if [ -n "${TMUX_CLIENT:-}" ]; then
    tmux select-window -t "${TMUX_SESSION}:${TMUX_WINDOW}" 2>/dev/null || true
    tmux switch-client -c "$TMUX_CLIENT" -t "$TMUX_SESSION" 2>/dev/null || true
  else
    tmux select-window -t "${TMUX_SESSION}:${TMUX_WINDOW}" 2>/dev/null || true
    tmux switch-client -t "$TMUX_SESSION" 2>/dev/null || true
  fi
fi
