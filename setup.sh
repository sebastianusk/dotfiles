#!/bin/sh
ln -sfn ~/dotfiles/.gitconfig ~/.gitconfig
ln -sfn ~/dotfiles/.tmux.conf.local ~/.tmux.conf.local
ln -sfn ~/dotfiles/config/nvim ~/.config/nvim
ln -sfn ~/dotfiles/config/alacritty.yml ~/.config/alacritty.yml

mkdir -p ~/.config/fish
ln -sfn ~/dotfiles/config/fish/config.fish ~/.config/fish/config.fish
ln -sfn ~/dotfiles/config/fish/fish_plugins ~/.config/fish/fish_plugins
ln -sfn ~/dotfiles/config/fish/alias.fish ~/.config/fish/alias.fish
ln -sfn ~/dotfiles/config/fish/funct.fish ~/.config/fish/funct.fish
ln -sfn ~/dotfiles/config/fish/opts.fish ~/.config/fish/opts.fish

ln -sfn ~/dotfiles/config/tmuxinator ~/.tmuxinator
ln -sfn ~/dotfiles/config/k9s ~/.config/k9s
ln -sfn ~/dotfiles/ctags.d ~/.ctags.d
ln -sfn ~/dotfiles/.asdfrc ~/.asdfrc
ln -sfn ~/dotfiles/config/starship.toml ~/.config/starship.toml

sudo ln -sfn $(which tmux) /usr/local/bin/tmux

if [[ $OSTYPE == 'darwin'* ]]; then
  ln -sfn ~/dotfiles/config/karabiner ~/.config/karabiner
  ln -sfn ~/dotfiles/config/karabiner.edn ~/.config/karabiner.edn
  ln -sfn ~/dotfiles/Brewfile ~/Brewfile
  ln -sfn ~/dotfiles/Brewfile.lock.json ~/Brewfile.lock.json
  ln -sfn ~/dotfiles/amethyst.yml ~/.amethyst.yml
fi
