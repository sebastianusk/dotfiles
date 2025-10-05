#!/bin/bash

# Zsh configuration sync script

echo "🔗 Syncing Zsh configuration..."

# Backup existing .zshrc if it exists
if [[ -f ~/.zshrc ]]; then
    echo "📋 Backing up existing .zshrc to .zshrc.backup"
    cp ~/.zshrc ~/.zshrc.backup
fi

# Create symlink to our zshrc
echo "🔗 Creating symlink to zshrc"
ln -sf ~/dotfiles/config/zsh/zshrc ~/.zshrc

echo "✅ Zsh configuration synced!"
echo "🔄 Restart your terminal or run: exec zsh"