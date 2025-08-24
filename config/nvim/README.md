# Neovim Configuration Sync

This directory contains the Neovim configuration and sync script for managing the setup.

## Usage

### Regular Sync (Default)
```bash
./sync.sh
```
- Updates `~/.config/nvim` symlink to latest dotfiles
- Preserves `~/.local/share/nvim` (plugins, LSP servers, data)
- Syncs plugins (updates existing, installs new ones)
- Fast and safe for daily use

### Clean Sync
```bash
./sync.sh --clean
```
- **⚠️ WARNING**: Completely removes all Neovim data
- Removes `~/.config/nvim` and `~/.local/share/nvim`
- Fresh installation of Lazy.nvim plugin manager
- Fresh installation of all plugins from scratch
- Use when you want a completely fresh start

### Help
```bash
./sync.sh --help
```
Shows usage information and available options.

## What Gets Synced

### Configuration Files
- All Lua configuration files in `lua/`
- Plugin configurations in `lua/plugins/`
- Keymaps, options, and autocommands

### Plugins (via Lazy.nvim)
- Smart-splits.nvim (Zellij/Tmux navigation)
- LSP configuration (Mason, nvim-lspconfig)
- Treesitter and syntax highlighting
- Git integration (Gitsigns, Neogit, Git-conflict)
- File explorer (nvim-tree)
- Fuzzy finder (Telescope)
- Completion (nvim-cmp)
- Debugging (nvim-dap)
- And many more...

## Key Features

- **Seamless Zellij Integration**: Ctrl+hjkl navigation between Neovim and Zellij panes
- **Complete LSP Setup**: Language servers, formatting, linting
- **Modern Plugin Ecosystem**: Latest Neovim plugins with Lazy.nvim
- **Self-Contained**: Sync script handles everything automatically

## Fresh Installation

On a new system, just run:
```bash
./sync.sh --clean
```

This will set up everything from scratch, including:
1. Neovim configuration symlink
2. Lazy.nvim plugin manager
3. All plugins and dependencies
4. Ready-to-use development environment

## Daily Updates

For regular updates to configuration changes:
```bash
./sync.sh
```

This preserves your existing plugins and data while updating the configuration.
