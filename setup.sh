#!/bin/sh
ln -sfn ~/dotfiles/.gitconfig ~/.gitconfig
ln -sfn ~/dotfiles/.tmux.conf ~/.tmux.conf
ln -sfn ~/dotfiles/config/nvim ~/.config/nvim
ln -sfn ~/dotfiles/config/mcphub ~/.config/mcphub
ln -sfn ~/dotfiles/config/alacritty ~/.config/alacritty

mkdir -p ~/.config/fish
ln -sfn ~/dotfiles/config/fish/config.fish ~/.config/fish/config.fish
ln -sfn ~/dotfiles/config/fish/fish_plugins ~/.config/fish/fish_plugins
ln -sfn ~/dotfiles/config/fish/alias.fish ~/.config/fish/alias.fish
ln -sfn ~/dotfiles/config/fish/funct.fish ~/.config/fish/funct.fish
ln -sfn ~/dotfiles/config/fish/opts.fish ~/.config/fish/opts.fish
cp ~/dotfiles/config/fish/secret.fish.example ~/dotfiles/config/fish/secret.fish
ln -sfn ~/dotfiles/config/fish/secret.fish ~/.config/fish/secret.fish

ln -sfn ~/dotfiles/config/goose/config.yaml ~/.config/goose/config.yaml
ln -sfn ~/dotfiles/config/goose/permission.yaml ~/.config/goose/permission.yaml

ln -sfn ~/dotfiles/config/tmuxinator ~/.tmuxinator
ln -sfn ~/dotfiles/config/k9s ~/.config/k9s
ln -sfn ~/dotfiles/ctags.d ~/.ctags.d
ln -sfn ~/dotfiles/.asdfrc ~/.asdfrc
ln -sfn ~/dotfiles/config/starship.toml ~/.config/starship.toml

ln -sfn ~/dotfiles/.tool-versions ~/.tool-versions
ln -sfn ~/dotfiles/.default-npm-packages ~/.default-npm-packages

mkdir -p /usr/local/bin/
sudo ln -sfn $(which fish) /usr/local/bin/fish
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

curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher && fisher update

git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
