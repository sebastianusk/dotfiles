#!/bin/sh
ln -sfn ~/dotfiles/.gitconfig ~/.gitconfig
ln -sfn ~/dotfiles/.tmux.conf ~/.tmux.conf
ln -sfn ~/dotfiles/config/nvim ~/.config/nvim
ln -sfn ~/dotfiles/config/mcphub ~/.config/mcphub
ln -sfn ~/dotfiles/config/alacritty ~/.config/alacritty

ln -sfn ~/dotfiles/config/goose ~/.config/goose
ln -sfn ~/dotfiles/config/opencode ~/.config/opencode
mkdir -p ~/.aws/amazonq
ln -sfn ~/dotfiles/config/amazonq/mcp.json ~/.aws/amazonq/mcp.json

ln -sfn ~/dotfiles/config/tmuxinator ~/.tmuxinator

# VS Code
mkdir -p ~/Library/Application\ Support/Code/User
ln -sfn ~/dotfiles/config/vscode/settings.json ~/Library/Application\ Support/Code/User/settings.json
ln -sfn ~/dotfiles/config/vscode/keybindings.json ~/Library/Application\ Support/Code/User/keybindings.json
ln -sfn ~/dotfiles/config/k9s ~/.config/k9s
ln -sfn ~/dotfiles/ctags.d ~/.ctags.d
ln -sfn ~/dotfiles/.asdfrc ~/.asdfrc
ln -sfn ~/dotfiles/config/starship.toml ~/.config/starship.toml

ln -sfn ~/dotfiles/.tool-versions ~/.tool-versions
ln -sfn ~/dotfiles/.default-npm-packages ~/.default-npm-packages

mkdir -p /usr/local/bin/
sudo ln -sfn $(which tmux) /usr/local/bin/tmux

if [[ $OSTYPE == 'darwin'* ]]; then
  ln -sfn ~/dotfiles/config/karabiner ~/.config/karabiner
  ln -sfn ~/dotfiles/config/karabiner.edn ~/.config/karabiner.edn
  ln -sfn ~/dotfiles/Brewfile ~/Brewfile
  ln -sfn ~/dotfiles/Brewfile.lock.json ~/Brewfile.lock.json
  ln -sfn ~/dotfiles/amethyst.yml ~/.amethyst.yml
fi

asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git || echo "Node.js plugin already added or failed to add."
asdf plugin add python https://github.com/asdf-community/asdf-python.git || echo "Python plugin already added or failed to add."
asdf plugin add flutter https://github.com/oerdnj/asdf-flutter.git || echo "Flutter plugin already added or failed to add."
asdf plugin add terraform https://github.com/asdf-community/asdf-hashicorp.git || echo "Terraform plugin already added or failed to add."

[ ! -d ~/.tmux/plugins/tpm ] && git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
