#!/bin/bash

OPENCODE_DIR="$HOME/.config/opencode"
DOTFILES_OPENCODE="$HOME/dotfiles/config/opencode"

mkdir -p "$OPENCODE_DIR"

# Remove existing files/symlinks and create new ones
rm -f "$OPENCODE_DIR/opencode.json"

ln -sf "$DOTFILES_OPENCODE/opencode.json" "$OPENCODE_DIR/opencode.json"

echo "✅ OpenCode configuration synced!"
