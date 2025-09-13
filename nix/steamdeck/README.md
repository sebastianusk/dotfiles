# Installing Nix Package Manager

```
curl -L https://install.determinate.systems/nix | sh -s -- install steam-deck
```

source: https://determinate.systems/blog/nix-on-the-steam-deck/

# Installing Home Manager

After installing Nix, install Home Manager:

```
nix-channel --add https://github.com/nix-community/home-manager/archive/release-25.05.tar.gz home-manager
nix-channel --update
nix-shell '<home-manager>' -A install
```

# Syncing Configuration

This directory contains the home.nix configuration file that gets symlinked to `~/.config/home-manager/`. To sync changes from this dotfiles directory to the home-manager config directory and apply them:

```
home-manager switch
```
