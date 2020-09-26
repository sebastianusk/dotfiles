#!/bin/sh

ln -sfn ~/dotfiles/.aliasrc ~/.aliasrc
ln -sfn ~/dotfiles/.gitconfig ~/.gitconfig
ln -sfn ~/dotfiles/.gitignore ~/.gitignore
ln -sfn ~/dotfiles/.initrc ~/.initrc
ln -sfn ~/dotfiles/.pathrc ~/.pathrc
ln -sfn ~/dotfiles/.personalrc ~/.personalrc
ln -sfn ~/dotfiles/.tmux.conf.local ~/.tmux.conf.local 
ln -sfn ~/dotfiles/tmuxinator ~/tmuxinator
mkdir -p ~/.config/nvim
ln -sfn ~/dotfiles/.vim/ftplugin ~/.config/nvim/ftplugin
ln -sfn ~/dotfiles/.vimrc ~/.config/nvim/init.vim
ln -sfn ~/dotfiles/.zshrc ~/.zshrc
