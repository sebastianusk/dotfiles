#!/bin/bash

# Tmux Configuration Sync Script
# This script sets up tmux and tmuxinator configurations

set -e

echo "🔧 Setting up tmux configuration..."

# Check if tmux is installed
if ! command -v tmux &>/dev/null; then
	echo "⚠️  WARNING: tmux is not installed"
	echo "   Please install tmux first: sudo apt install tmux (Ubuntu/Debian) or brew install tmux (macOS)"
	exit 1
fi

# Check if tmuxinator is installed
if ! command -v tmuxinator &>/dev/null; then
	echo "⚠️  WARNING: tmuxinator is not installed"
	echo "   Please install tmuxinator first: gem install tmuxinator"
	exit 1
fi

echo "✅ Dependencies check passed"

# Setup tmux configuration
echo "📝 Linking tmux configuration..."
ln -sfn ~/dotfiles/config/tmux/tmux.conf ~/.tmux.conf
echo "   ~/.tmux.conf -> ~/dotfiles/config/tmux/tmux.conf"

# Make cluster_info.sh executable
chmod +x ~/dotfiles/config/tmux/cluster_info.sh
echo "   cluster_info.sh made executable"

# Setup tmuxinator sessions
echo "📂 Linking tmuxinator sessions..."
# Remove existing ~/.tmuxinator if it's a directory with files
if [ -d ~/.tmuxinator ] && [ ! -L ~/.tmuxinator ]; then
	echo "   Backing up existing ~/.tmuxinator to ~/.tmuxinator.backup"
	mv ~/.tmuxinator ~/.tmuxinator.backup
fi
# Create symlink to the entire tmuxinator directory
ln -sfn ~/dotfiles/config/tmux/tmuxinator ~/.tmuxinator
echo "   ~/.tmuxinator -> ~/dotfiles/config/tmux/tmuxinator"

# Install TPM (Tmux Plugin Manager) if not already installed
if [ ! -d ~/.tmux/plugins/tpm ]; then
	echo "📦 Installing Tmux Plugin Manager (TPM)..."
	git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
	echo "   TPM installed to ~/.tmux/plugins/tpm"
else
	echo "✅ TPM already installed"
fi

# Install tmux plugins automatically
if [ -f ~/.tmux/plugins/tpm/scripts/install_plugins.sh ]; then
	echo "🔌 Installing tmux plugins..."
	~/.tmux/plugins/tpm/scripts/install_plugins.sh
	echo "✅ Tmux plugins installed"
fi

echo ""
echo "🎉 Tmux setup complete!"
echo ""
echo "Available tmuxinator sessions:"
ls -1 ~/.tmuxinator/ | sed 's/\.yml$//' | sed 's/^/   - /'
echo ""
echo "Usage:"
echo "   tmuxinator start <session_name>"
echo "   tmux new-session -d -s <session_name>"
