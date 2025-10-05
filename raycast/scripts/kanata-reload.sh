#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Kanata Reload
# @raycast.mode compact

# Optional parameters:
# @raycast.icon ⌨️
# @raycast.packageName System

# Documentation:
# @raycast.description Reload kanata keyboard configuration
# @raycast.author admin

# Change to the kanata mac directory and run sync script
cd "$HOME/dotfiles/config/kanata/mac" && ./sync-mac.sh

echo "✅ Kanata configuration reloaded"