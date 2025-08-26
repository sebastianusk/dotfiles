#!/bin/bash

# Alacritty configuration sync script
# This script creates symlinks for Alacritty configuration files
# and installs Catppuccin theme

echo "🌴 Syncing Alacritty configuration..."

# Complete cleanup - delete entire Alacritty config directory
echo "🧹 Completely removing existing Alacritty configuration..."
rm -rf ~/.config/alacritty

# Create fresh Alacritty config directory
echo "📁 Creating fresh Alacritty config directory..."
mkdir -p ~/.config/alacritty
mkdir -p ~/.config/alacritty/catppuccin

# Create symlinks for Alacritty configuration files
echo "🔗 Creating symlinks..."
ln -sfn ~/dotfiles/config/alacritty/alacritty.toml ~/.config/alacritty/alacritty.toml

# Download Catppuccin Mocha theme
echo "🎨 Installing Catppuccin Mocha theme..."
if command -v curl >/dev/null 2>&1; then
    echo "📥 Downloading catppuccin-mocha.toml..."
    curl -sL -o ~/.config/alacritty/catppuccin/catppuccin-mocha.toml \
        https://github.com/catppuccin/alacritty/raw/main/catppuccin-mocha.toml
    
    if [ -f ~/.config/alacritty/catppuccin/catppuccin-mocha.toml ]; then
        echo "✅ Catppuccin Mocha theme downloaded successfully"
    else
        echo "❌ Failed to download Catppuccin Mocha theme"
    fi
else
    echo "⚠️  curl not found, skipping theme download"
    echo "   Please install curl or manually download the theme from:"
    echo "   https://github.com/catppuccin/alacritty/raw/main/catppuccin-mocha.toml"
fi

# Verify symlinks
echo "🔍 Verifying configuration..."
if [ -L ~/.config/alacritty/alacritty.toml ]; then
    echo "✅ alacritty.toml symlink created"
else
    echo "❌ alacritty.toml symlink failed"
fi

if [ -f ~/.config/alacritty/catppuccin/catppuccin-mocha.toml ]; then
    echo "✅ Catppuccin theme file present"
else
    echo "❌ Catppuccin theme file missing"
fi

echo ""
echo "✅ Alacritty configuration sync complete!"
echo ""
echo "📝 Summary:"
echo "   • Completely removed old ~/.config/alacritty directory"
echo "   • Created fresh directory with symlinks"
echo "   • Symlinked alacritty.toml configuration"
echo "   • Downloaded Catppuccin Mocha theme"
echo "   • Created catppuccin theme directory"
echo ""
echo "🔄 To apply changes, restart Alacritty or open a new window"
echo "💡 Make sure your alacritty.toml includes:"
echo "   import = [\"~/.config/alacritty/catppuccin/catppuccin-mocha.toml\"]"
