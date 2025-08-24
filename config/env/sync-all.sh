#!/bin/bash
# Master sync script - syncs environment to all tools
# Run this from the env directory

SCRIPT_DIR="$(dirname "$0")"

echo "🔄 Syncing environment variables from YAML to all tools..."
echo ""

# Sync to fish
echo "📟 Syncing to Fish..."
"$SCRIPT_DIR/../fish/sync-env.sh"
echo ""

# Sync to zellij  
echo "🖥️  Syncing to Zellij..."
"$SCRIPT_DIR/../zellij/sync-env.sh"
echo ""

echo "🎉 All environments synced successfully!"
echo ""
echo "Next steps:"
echo "  • Restart fish shell: source ~/.config/fish/config.fish"
echo "  • Restart zellij or start new session"
