#!/bin/sh
ln -sfn ~/dotfiles/.gitconfig ~/.gitconfig
ln -sfn ~/dotfiles/.tmux.conf.local ~/.tmux.conf.local
ln -sfn ~/dotfiles/config/nvim ~/.config/nvim
ln -sfn ~/dotfiles/config/alacritty.yml ~/.config/alacritty.yml
mkdir -p ~/.config/fish
ln -sfn ~/dotfiles/config/fish/conf.d ~/.config/fish/conf.d
ln -sfn ~/dotfiles/config/fish/config.fish ~/.config/fish/config.fish
ln -sfn ~/dotfiles/config/fish/fish_plugins ~/.config/fish/fish_plugins
ln -sfn ~/dotfiles/config/tmuxinator ~/.tmuxinator
ln -sfn ~/dotfiles/config/k9s ~/.config/k9s
ln -sfn ~/dotfiles/ctags.d ~/.ctags.d

if [[ $OSTYPE == 'darwin'* ]]; then
  ln -sfn ~/dotfiles/config/karabiner ~/.config/karabiner
  ln -sfn ~/dotfiles/config/karabiner.edn ~/.config/karabiner.edn
  ln -sfn ~/dotfiles/Brewfile ~/Brewfile
  ln -sfn ~/dotfiles/Brewfile.lock.json ~/Brewfile.lock.json
  ln -sfn ~/dotfiles/amethyst.yml ~/.amethyst.yml
fi
