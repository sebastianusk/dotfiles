#!/bin/bash

# Zellij configuration sync script
# This script creates symlinks for all Zellij configuration files

echo "🖥️  Syncing Zellij configuration..."

# Complete cleanup - delete entire Zellij config directory
echo "🧹 Completely removing existing Zellij configuration..."
rm -rf ~/.config/zellij

# Create fresh Zellij config directory
echo "📁 Creating fresh Zellij config directory..."
mkdir -p ~/.config/zellij
mkdir -p ~/.config/zellij/layouts

# Create symlinks for Zellij configuration files
echo "🔗 Creating symlinks..."
ln -sfn ~/dotfiles/config/zellij/config.kdl ~/.config/zellij/config.kdl

# Symlink layout files
ln -sfn ~/dotfiles/config/zellij/layouts/vsplit.kdl ~/.config/zellij/layouts/vsplit.kdl

echo ""
echo "✅ Zellij configuration sync complete!"
echo ""
echo "📝 Summary:"
echo "   • Completely removed old ~/.config/zellij directory"
echo "   • Created fresh directory with symlinks"
echo "   • Symlinked config.kdl with Ctrl+hjkl navigation"
echo "   • Symlinked layouts/vsplit.kdl"
echo ""
echo "🔄 To apply changes, restart Zellij or start a new session"
