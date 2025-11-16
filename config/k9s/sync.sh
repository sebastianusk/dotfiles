#!/bin/bash

K9S_DIR="$HOME/Library/Application Support/k9s"
DOTFILES_K9S="$HOME/dotfiles/config/k9s"

mkdir -p "$K9S_DIR"

# Remove existing symlinks and create new ones
rm -f "$K9S_DIR/config.yaml" "$K9S_DIR/aliases.yaml" "$K9S_DIR/plugins.yaml" "$K9S_DIR/skins"

ln -sf "$DOTFILES_K9S/config.yaml" "$K9S_DIR/config.yaml"
ln -sf "$DOTFILES_K9S/aliases.yaml" "$K9S_DIR/aliases.yaml"
ln -sf "$DOTFILES_K9S/plugins.yaml" "$K9S_DIR/plugins.yaml"
ln -sf "$DOTFILES_K9S/skins" "$K9S_DIR/skins"

echo "✅ K9s configuration synced!"
