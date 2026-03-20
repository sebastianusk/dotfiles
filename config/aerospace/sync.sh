mkdir -p ~/.config/aerospace
ln -sfn ~/dotfiles/config/aerospace/aerospace.toml ~/.config/aerospace/aerospace.toml
defaults write -g NSAutomaticWindowAnimationsEnabled -bool false
defaults write com.apple.dock expose-group-apps -bool true && killall Dock
defaults write com.apple.spaces spans-displays -bool true && killall SystemUIServer
