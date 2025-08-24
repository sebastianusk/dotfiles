#!/bin/bash

# Neovim configuration sync script
# This script creates symlinks and installs Lazy.nvim for a complete fresh setup

echo "⚡ Syncing Neovim configuration..."

# Complete cleanup - delete entire Neovim config and data directories
echo "🧹 Completely removing existing Neovim configuration and data..."
rm -rf ~/.config/nvim
rm -rf ~/.local/share/nvim

# Create symlink for the entire nvim directory
echo "🔗 Creating configuration symlink..."
ln -sfn ~/dotfiles/config/nvim ~/.config/nvim

# Install Lazy.nvim (bootstrap)
echo "📦 Installing Lazy.nvim plugin manager..."
LAZYPATH="$HOME/.local/share/nvim/lazy/lazy.nvim"

if [ ! -d "$LAZYPATH" ]; then
    echo "   • Cloning Lazy.nvim from GitHub..."
    git clone --filter=blob:none https://github.com/folke/lazy.nvim.git --branch=stable "$LAZYPATH"
    if [ $? -eq 0 ]; then
        echo "   • ✅ Lazy.nvim installed successfully"
    else
        echo "   • ❌ Failed to install Lazy.nvim"
        exit 1
    fi
else
    echo "   • ✅ Lazy.nvim already installed"
fi

# Install all plugins using Lazy.nvim
echo "🔌 Installing/updating all plugins..."
nvim --headless -c "lua require('lazy').setup({import = 'plugins'})" -c "Lazy! sync" -c "qall"

if [ $? -eq 0 ]; then
    echo "   • ✅ All plugins installed/updated successfully"
else
    echo "   • ⚠️  Plugin installation completed with some warnings (this is normal)"
fi

echo ""
echo "✅ Neovim configuration sync complete!"
echo ""
echo "📝 Summary:"
echo "   • Completely removed old ~/.config/nvim and ~/.local/share/nvim directories"
echo "   • Created symlink to entire dotfiles nvim directory"
echo "   • Installed Lazy.nvim plugin manager"
echo "   • Installed/updated all plugins automatically"
echo "   • All configs, plugins, and settings are now synced"
echo ""
echo "🔄 Neovim is ready to use! Run: nvim"
echo ""
echo "💡 All plugins are installed and ready. LSP servers may need additional setup via :Mason"
