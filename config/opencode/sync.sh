#!/bin/bash

OPENCODE_DIR="$HOME/.config/opencode"
DOTFILES_OPENCODE="$HOME/dotfiles/config/opencode"

mkdir -p "$OPENCODE_DIR"

# Remove existing files/symlinks and create new ones
rm -f "$OPENCODE_DIR/opencode.json" "$OPENCODE_DIR/tui.json" "$OPENCODE_DIR/oh-my-openagent.jsonc" "$OPENCODE_DIR/vibeguard.config.json" "$OPENCODE_DIR/opencode-mem.jsonc"
ln -sf "$DOTFILES_OPENCODE/opencode.json" "$OPENCODE_DIR/opencode.json"
ln -sf "$DOTFILES_OPENCODE/tui.json" "$OPENCODE_DIR/tui.json"
ln -sf "$DOTFILES_OPENCODE/oh-my-openagent.jsonc" "$OPENCODE_DIR/oh-my-openagent.jsonc"
ln -sf "$DOTFILES_OPENCODE/vibeguard.config.json" "$OPENCODE_DIR/vibeguard.config.json"
ln -sf "$DOTFILES_OPENCODE/opencode-mem.jsonc" "$OPENCODE_DIR/opencode-mem.jsonc"

echo "✅ OpenCode configuration synced!"
