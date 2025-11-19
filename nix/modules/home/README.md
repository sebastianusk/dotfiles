# Home Manager Modules

User-level configuration modules for Home Manager.

## Available Modules

### terminal.nix
Terminal environment with essential development tools:
- **alacritty**: Terminal emulator
- **zsh**: Shell with completion and syntax highlighting
- **tmux**: Terminal multiplexer
- **neovim**: Editor (with vi/vim aliases, set as default editor)
- **starship**: Cross-shell prompt

#### Usage
```nix
{
  imports = [ ../../modules/home/terminal.nix ];

  modules.terminal = {
    enable = true;

    # Optional: override dotfiles path (default: ~/dotfiles)
    # dotfilesPath = "/path/to/your/dotfiles";

    # Optional: disable specific packages
    # packages.alacritty.enable = false;
  };
}
```

**Configuration Management:**
- Symlinks existing config files from `~/dotfiles/config/` to `~/.config/`
- Uses `mkOutOfStoreSymlink` to link to mutable dotfiles directory
- Changes to dotfiles are immediately reflected without rebuilding

## Creating New Modules

Home Manager modules should:
- Be user-specific (not system-wide)
- Use `home.packages` for binaries
- Use `programs.*` for declarative configuration
- Provide enable options for flexibility
- Be composable with other modules
