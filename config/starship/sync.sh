#!/bin/bash

# Starship configuration sync script
# This script creates symlinks for Starship configuration files

echo "🚀 Syncing Starship configuration..."

# Get script directory for relative paths
SCRIPT_DIR="$(dirname "$0")"

# Create starship config directory if it doesn't exist
echo "📁 Creating Starship config directory..."
mkdir -p ~/.config

# Create symlink for Starship configuration
echo "🔗 Creating starship.toml symlink..."
ln -sfn ~/dotfiles/config/starship/starship.toml ~/.config/starship.toml

echo ""
echo "✅ Starship configuration sync complete!"
echo ""
echo "📝 Summary:"
echo "   • Created symlink for starship.toml"
echo ""
echo "🔄 Starship will use the new configuration on next shell start"
