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

### wayland.nix
Wayland desktop environment with Hyprland and essential tools:
- **hyprland**: Wayland compositor/window manager (user-space config)
- **rofi**: Application launcher with power menu
- **waybar**: Status bar for Wayland
- **dunst**: Notification daemon
- **wl-clipboard**: Wayland clipboard utilities
- **grimblast**: Screenshot tool
- Additional utilities: wlr-randr, xdg-utils, grim, slurp

#### Usage
```nix
{
  imports = [ ../../modules/home/wayland.nix ];

  modules.wayland = {
    enable = true;

    # Optional: customize rofi theme
    rofi.theme = "gruvbox-dark";

    # Optional: override dotfiles path (default: ~/dotfiles)
    # dotfilesPath = "/path/to/your/dotfiles";

    # Optional: disable specific packages
    # packages.waybar.enable = false;
    # packages.dunst.enable = false;
  };
}
```

**Configuration Management:**
- Symlinks config files from `~/dotfiles/config/` (hypr, waybar, dunst)
- Sets Wayland-specific environment variables (MOZ_ENABLE_WAYLAND, QT_QPA_PLATFORM, etc.)
- Uses `mkOutOfStoreSymlink` for mutable configuration
- Only creates symlinks if config directories exist

**Note:** System-level Hyprland configuration (programs.hyprland.enable) must be set in the host configuration (`nix/hosts/*/default.nix`), as it requires system-wide privileges.

## Creating New Modules

Home Manager modules should:
- Be user-specific (not system-wide)
- Use `home.packages` for binaries
- Use `programs.*` for declarative configuration
- Provide enable options for flexibility
- Be composable with other modules
