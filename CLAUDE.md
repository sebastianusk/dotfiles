# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a comprehensive multi-platform dotfiles repository supporting macOS (via Homebrew) and NixOS (Steam Deck), featuring extensive configurations for terminal environments, editors, and system tools.

## Platform-Specific Setup

### macOS Setup
```bash
# Initial setup (one-time)
./bootstrap.sh  # Installs oh-my-zsh, nvim plug, oh-my-tmux

# Link dotfiles
./setup.sh      # Creates symlinks for all configuration files

# Install packages
brew bundle     # Uses Brewfile for package management
```

### NixOS Setup (Steam Deck)
```bash
# Build and activate configuration
sudo nixos-rebuild switch --flake ./nix#steamdeck

# Update flake inputs
nix flake update ./nix

# Test configuration without activation
sudo nixos-rebuild test --flake ./nix#steamdeck
```

## Architecture Overview

### Two-Layer Configuration System

**Traditional Dotfiles (macOS/Linux):**
- `setup.sh` creates symlinks from `~/dotfiles/config/*` to `~/.config/`
- Configuration files in `config/` directory for all applications
- Package management via Homebrew (macOS) or system package manager

**NixOS Declarative Configuration:**
- Flake-based configuration in `nix/` directory
- Three-tier structure: hosts → modules → users
- Home Manager integration for user-level configuration
- Single source of truth for system and user packages

### Nix Configuration Structure

The `nix/` directory implements a modular NixOS configuration:

**`nix/flake.nix`**: Entry point defining:
- Inputs: nixpkgs, home-manager, jovian (Steam Deck)
- `mkHost` helper function for creating host configurations
- Host definitions with system, user, and extra modules

**`nix/hosts/`**: Machine-specific configurations
- Each host has `default.nix` (main config) and `hardware-configuration.nix`
- Currently supports: `steamdeck` (with Jovian-NixOS and Hyprland)
- Hosts import modules and customize with options

**`nix/modules/`**: Reusable configuration modules
- System-level modules for NixOS configuration
- `modules/home/`: Home Manager modules for user-level configuration
- Self-contained functionality units with enable options
- Composable with other modules

**`nix/users/`**: User-specific configurations
- Home Manager settings for each user
- Personal packages and dotfiles
- Git config, shell preferences, user applications

### Key Configuration Files

**Shell Configurations:**
- `config/fish/config.fish`: Fish shell main config, sources generated env.fish
- `config/fish/alias.fish`, `config/fish/funct.fish`: Fish aliases and functions
- `config/fish/opts.fish`: Fish options
- `config/fish/secret.fish`: Secrets (not tracked, copy from secret.fish.example)
- `.zshrc`: zsh configuration (legacy, macOS primary)

**Editor Configurations:**
- `config/nvim/`: Neovim configuration with Lazy.nvim plugin manager
- Seamless Zellij/Tmux navigation with Ctrl+hjkl
- Complete LSP setup, Treesitter, Git integration

**Keyboard Remapping:**
- `config/kanata/kanata.kbd`: Main Kanata configuration
- `config/kanata/mac/`: macOS-specific setup and scripts
- `config/kanata/steamdeck/`: Steam Deck/Linux setup with systemd service
- Homerow modifiers: Caps Lock (Esc/Cmd+Opt), ASDF/JKL; (Shift/Alt/Super/Ctrl)
- Space hold for navigation layer (hjkl → arrows)

**Terminal Multiplexers:**
- `config/tmux/`: Tmux configuration with oh-my-tmux
- `config/zellij/`: Zellij configuration
- Both support seamless Neovim pane navigation

## Common Commands

### Neovim Sync
```bash
# Regular sync (preserves plugins and data)
cd config/nvim && ./sync.sh

# Clean install (removes all Neovim data)
cd config/nvim && ./sync.sh --clean
```

### Kanata Keyboard Remapper
```bash
# macOS
cd config/kanata/mac && ./sync-mac.sh

# Steam Deck/Linux
cd config/kanata/steamdeck && ./sync-steamdeck.sh
```

### LiteLLM Proxy (AWS Bedrock)
```bash
# Start proxy server (http://localhost:8000)
cd model && ./model.sh start

# Check status
cd model && ./model.sh status

# Stop server
cd model && ./model.sh stop

# Run tests
cd model/test && ./run-tests.sh quick
```

### NixOS Management
```bash
# Apply configuration changes
sudo nixos-rebuild switch --flake ./nix#steamdeck

# Test configuration without persisting
sudo nixos-rebuild test --flake ./nix#steamdeck

# Update all flake inputs
cd nix && nix flake update

# Check what would change
sudo nixos-rebuild dry-build --flake ./nix#steamdeck
```

## Critical Patterns

### Creating Home Manager Modules
Home Manager modules go in `nix/modules/home/`:
1. Create module file (e.g., `terminal.nix`) with `options` and `config`
2. Use `home.packages` for packages, `programs.*` for declarative config
3. Import in user config: `imports = [ ../../modules/home/terminal.nix ];`
4. Enable: `modules.<module-name>.enable = true;`
5. Provide per-package enable options for flexibility

Example structure:
```nix
{ config, lib, pkgs, ... }:
with lib;
let cfg = config.modules.terminal;
in {
  options.modules.terminal = {
    enable = mkEnableOption "terminal environment";
    packages.neovim.enable = mkOption { type = types.bool; default = true; };
  };
  config = mkIf cfg.enable {
    home.packages = [ (mkIf cfg.packages.neovim.enable pkgs.neovim) ];
  };
}
```

### Adding New NixOS Host
1. Create `nix/hosts/<hostname>/` directory
2. Add `default.nix` and `hardware-configuration.nix`
3. Create user config in `nix/users/<username>/default.nix`
4. Register host in `nix/flake.nix` nixosConfigurations
5. Use `mkHost` helper: `mkHost "hostname" "system" "user" [extraModules]`

### Environment Variables
- Generate static environment variables with `config/env/generator.sh`
- Outputs to `config/fish/env.fish` and `config/zsh/env.sh`
- Source secrets from `config/fish/secret.fish` (not tracked)
- Fish config sources env.fish before loading interactive features

### Symlink Management
- All config symlinks created by `setup.sh`
- Broken symlinks indicate missing source files or structural changes
- Platform-specific sections in setup.sh (darwin vs linux)
- Always use absolute paths in symlinks

### Testing Infrastructure
- Model proxy has comprehensive test suite in `model/test/`
- Use `run-tests.sh` wrapper for easy test selection
- Quick tests (~30s) validate core functionality
- Full tests (~3-5min) for comprehensive validation

## Important Notes

- Steam Deck configuration uses Jovian-NixOS with Hyprland desktop
- ASDF manages runtime versions (Node.js, Python, Flutter, Terraform)
- Fisher manages Fish shell plugins
- Brewfile.lock.json tracks exact Homebrew package versions
- Kanata requires platform-specific setup (sudo access on macOS, udev rules on Linux)
- LiteLLM proxy uses AWS profile "personal" and ap-southeast-1 region
