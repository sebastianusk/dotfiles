#!/bin/bash

HAMMERSPOON_DIR="$HOME/.hammerspoon"
DOTFILES_HAMMERSPOON="$HOME/dotfiles/config/hammerspoon"
SPOONS_DIR="$DOTFILES_HAMMERSPOON/Spoons"

mkdir -p "$HAMMERSPOON_DIR"
mkdir -p "$SPOONS_DIR"

ln -sf "$DOTFILES_HAMMERSPOON/init.lua" "$HAMMERSPOON_DIR/init.lua"

if [ ! -d "$SPOONS_DIR/Swipe.spoon" ]; then
	git clone https://github.com/mogenson/Swipe.spoon.git "$SPOONS_DIR/Swipe.spoon"
fi

ln -sfn "$SPOONS_DIR" "$HAMMERSPOON_DIR/Spoons"

echo "✅ Hammerspoon configuration synced!"
