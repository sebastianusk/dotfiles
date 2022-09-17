#!/bin/sh

ln -sfn ~/dotfiles/.gitconfig ~/.gitconfig
ln -sfn ~/dotfiles/.pathrc ~/.pathrc
ln -sfn ~/dotfiles/.personalrc ~/.personalrc
ln -sfn ~/dotfiles/.tmux.conf.local ~/.tmux.conf.local
ln -sfn ~/dotfiles/tmuxinator ~/tmuxinator
mkdir -p ~/.config/nvim
ln -sfn ~/dotfiles/.vim/ftplugin ~/.config/nvim/ftplugin
ln -sfn ~/dotfiles/.vimrc ~/.config/nvim/init.vim

source ~/dotfiles/bootstrap.sh
ln -sfn ~/dotfiles/.zshrc ~/.zshrc

ln -sfn ~/dotfiles/tmuxinator ~/.tmuxinator
