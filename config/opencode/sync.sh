#!/bin/bash

set -euo pipefail

OPENCODE_DIR="$HOME/.config/opencode"
DOTFILES_OPENCODE="$HOME/dotfiles/config/opencode"
DOTFILES_COMMANDS="$HOME/dotfiles/config/commands"

mkdir -p "$OPENCODE_DIR"

for source in \
  "$DOTFILES_OPENCODE/opencode.json" \
  "$DOTFILES_OPENCODE/tui.json" \
  "$DOTFILES_OPENCODE/AGENTS.md" \
  "$DOTFILES_OPENCODE/vibeguard.config.json" \
  "$DOTFILES_OPENCODE/hermes-memory.jsonc" \
  "$DOTFILES_OPENCODE/approval-review.jsonc" \
  "$DOTFILES_OPENCODE/opencode-notifier.json" \
  "$DOTFILES_OPENCODE/extensions" \
  "$DOTFILES_OPENCODE/agents" \
  "$DOTFILES_OPENCODE/skills" \
  "$DOTFILES_COMMANDS" \
  "$DOTFILES_OPENCODE/scripts/notify-with-focus.sh" \
  "$DOTFILES_OPENCODE/scripts/focus-opencode.sh"; do
  [[ -e "$source" ]] || {
    echo "❌ Missing source: $source" >&2
    exit 1
  }
done

link_file() {
  local source="$1"
  local target="$2"

  if [[ -e "$target" && ! -L "$target" ]]; then
    echo "⚠️  Skipping $target because it is not a symlink"
    return
  fi

  rm -f "$target"
  ln -s "$source" "$target"
}

link_file "$DOTFILES_OPENCODE/opencode.json" "$OPENCODE_DIR/opencode.json"
link_file "$DOTFILES_OPENCODE/tui.json" "$OPENCODE_DIR/tui.json"
link_file "$DOTFILES_OPENCODE/vibeguard.config.json" "$OPENCODE_DIR/vibeguard.config.json"
link_file "$DOTFILES_OPENCODE/hermes-memory.jsonc" "$OPENCODE_DIR/hermes-memory.jsonc"
link_file "$DOTFILES_OPENCODE/approval-review.jsonc" "$OPENCODE_DIR/approval-review.jsonc"
link_file "$DOTFILES_OPENCODE/opencode-notifier.json" "$OPENCODE_DIR/opencode-notifier.json"
link_file "$DOTFILES_OPENCODE/AGENTS.md" "$OPENCODE_DIR/AGENTS.md"
link_file "$DOTFILES_COMMANDS" "$OPENCODE_DIR/commands"

# Sync OpenCode-specific skills. Shared and brain-vault skills are loaded
# through opencode.json skills.paths and are intentionally not copied here.
if [[ ! -e "$OPENCODE_DIR/skills" || -L "$OPENCODE_DIR/skills" ]]; then
  rm -f "$OPENCODE_DIR/skills"
  ln -s "$DOTFILES_OPENCODE/skills" "$OPENCODE_DIR/skills"
else
  echo "⚠️  Skipping $OPENCODE_DIR/skills because it is not a symlink"
fi

if [[ ! -e "$OPENCODE_DIR/extensions" || -L "$OPENCODE_DIR/extensions" ]]; then
  rm -f "$OPENCODE_DIR/extensions"
  ln -s "$DOTFILES_OPENCODE/extensions" "$OPENCODE_DIR/extensions"
else
  echo "⚠️  Skipping $OPENCODE_DIR/extensions because it is not a symlink"
fi

if [[ ! -e "$OPENCODE_DIR/agents" || -L "$OPENCODE_DIR/agents" ]]; then
  rm -f "$OPENCODE_DIR/agents"
  ln -s "$DOTFILES_OPENCODE/agents" "$OPENCODE_DIR/agents"
else
  echo "⚠️  Skipping $OPENCODE_DIR/agents because it is not a symlink"
fi

# Sync scripts
mkdir -p "$OPENCODE_DIR/scripts"
link_file "$DOTFILES_OPENCODE/scripts/notify-with-focus.sh" "$OPENCODE_DIR/scripts/notify-with-focus.sh"
link_file "$DOTFILES_OPENCODE/scripts/focus-opencode.sh" "$OPENCODE_DIR/scripts/focus-opencode.sh"
chmod +x "$DOTFILES_OPENCODE/scripts/notify-with-focus.sh"
chmod +x "$DOTFILES_OPENCODE/scripts/focus-opencode.sh"

echo "✅ OpenCode configuration synced!"
