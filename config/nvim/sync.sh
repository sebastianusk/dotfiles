#!/bin/bash

# Neovim configuration sync script
# Usage: 
#   ./sync.sh         - Resync configuration only (preserves plugins)
#   ./sync.sh --clean - Complete clean sync (removes Lazy.nvim and all plugins)
#   ./sync.sh --help  - Show this help message

show_help() {
    echo "Neovim Configuration Sync Script"
    echo ""
    echo "Usage:"
    echo "  ./sync.sh         - Resync configuration only (preserves plugins)"
    echo "  ./sync.sh --clean - Complete clean sync (removes Lazy.nvim and all plugins)"
    echo "  ./sync.sh --help  - Show this help message"
    echo ""
    echo "Modes:"
    echo "  Regular sync:"
    echo "    • Updates ~/.config/nvim symlink to latest dotfiles"
    echo "    • Preserves ~/.local/share/nvim (plugins, LSP servers, data)"
    echo "    • Lazy.nvim will automatically sync plugins when Neovim starts"
    echo "    • Fast and efficient for daily use"
    echo ""
    echo "  Clean sync (--clean):"
    echo "    • Completely removes ~/.config/nvim and ~/.local/share/nvim"
    echo "    • Fresh installation of Lazy.nvim plugin manager"
    echo "    • Lazy.nvim will install all plugins fresh when Neovim starts"
    echo "    • Use when you want a completely fresh start"
    echo ""
}

# Parse command line arguments
CLEAN_SYNC=false
if [[ "$1" == "--clean" ]]; then
    CLEAN_SYNC=true
elif [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    show_help
    exit 0
elif [[ -n "$1" ]]; then
    echo "❌ Unknown option: $1"
    echo ""
    show_help
    exit 1
fi

if [[ "$CLEAN_SYNC" == true ]]; then
    echo "⚡ Performing CLEAN Neovim configuration sync..."
    echo ""
    echo "⚠️  WARNING: This will completely remove all plugins and data!"
    echo "   • ~/.config/nvim will be removed"
    echo "   • ~/.local/share/nvim will be removed (all plugins, LSP servers, etc.)"
    echo ""
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Clean sync cancelled."
        exit 0
    fi
    echo ""
    
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
    
    echo "   • Cloning Lazy.nvim from GitHub..."
    git clone --filter=blob:none https://github.com/folke/lazy.nvim.git --branch=stable "$LAZYPATH"
    if [ $? -eq 0 ]; then
        echo "   • ✅ Lazy.nvim installed successfully"
    else
        echo "   • ❌ Failed to install Lazy.nvim"
        exit 1
    fi
    
    echo ""
    echo "✅ CLEAN Neovim configuration sync complete!"
    echo ""
    echo "📝 Summary:"
    echo "   • Completely removed old ~/.config/nvim and ~/.local/share/nvim directories"
    echo "   • Created fresh symlink to dotfiles nvim directory"
    echo "   • Installed Lazy.nvim plugin manager from scratch"
    echo "   • Configuration is ready for fresh start"
    echo ""
    echo "🔄 Neovim is ready to use! Run: nvim"
    echo "💡 Lazy.nvim will automatically install all plugins when Neovim starts"
    echo ""
    echo "💡 All plugins will be installed fresh. LSP servers may need additional setup via :Mason"
    
else
    echo "⚡ Syncing Neovim configuration (preserving plugins)..."
    echo ""
    
    # Only remove and recreate the config symlink (preserve ~/.local/share/nvim)
    echo "🔗 Updating configuration symlink..."
    rm -rf ~/.config/nvim
    ln -sfn ~/dotfiles/config/nvim ~/.config/nvim
    
    # Check if Lazy.nvim exists, install if missing
    LAZYPATH="$HOME/.local/share/nvim/lazy/lazy.nvim"
    if [ ! -d "$LAZYPATH" ]; then
        echo "📦 Installing missing Lazy.nvim plugin manager..."
        git clone --filter=blob:none https://github.com/folke/lazy.nvim.git --branch=stable "$LAZYPATH"
        if [ $? -eq 0 ]; then
            echo "   • ✅ Lazy.nvim installed successfully"
        else
            echo "   • ❌ Failed to install Lazy.nvim"
            exit 1
        fi
    else
        echo "📦 Lazy.nvim already installed, skipping..."
    fi
    
    echo ""
    echo "✅ Neovim configuration sync complete!"
    echo ""
    echo "📝 Summary:"
    echo "   • Updated configuration symlink to latest dotfiles"
    echo "   • Preserved existing ~/.local/share/nvim directory (plugins, data, etc.)"
    echo "   • Configuration changes are now active"
    echo ""
    echo "🔄 Neovim is ready to use! Run: nvim"
    echo "💡 Lazy.nvim will automatically sync plugins when Neovim starts"
    echo ""
    echo "💡 Use './sync.sh --clean' for a complete fresh installation"
fi
