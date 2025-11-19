{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.wayland;
in
{
  options.modules.wayland = {
    enable = mkEnableOption "Wayland desktop environment with Hyprland and essential tools";

    dotfilesPath = mkOption {
      type = types.str;
      default = "${config.home.homeDirectory}/dotfiles";
      description = "Path to dotfiles repository";
    };

    packages = {
      hyprland.enable = mkOption {
        type = types.bool;
        default = true;
        description = "Install and configure Hyprland window manager";
      };

      rofi.enable = mkOption {
        type = types.bool;
        default = true;
        description = "Install and configure Rofi application launcher";
      };

      waybar.enable = mkOption {
        type = types.bool;
        default = true;
        description = "Install Waybar status bar";
      };

      dunst.enable = mkOption {
        type = types.bool;
        default = true;
        description = "Install Dunst notification daemon";
      };

      wl-clipboard.enable = mkOption {
        type = types.bool;
        default = true;
        description = "Install wl-clipboard for Wayland clipboard utilities";
      };

      grimblast.enable = mkOption {
        type = types.bool;
        default = true;
        description = "Install grimblast for screenshots";
      };
    };

    rofi = {
      theme = mkOption {
        type = types.str;
        default = "gruvbox-dark";
        description = "Rofi theme to use";
      };
    };
  };

  config = mkIf cfg.enable {
    # User packages - install packages without overly declarative config
    # since we may use dotfiles via symlinks for some
    home.packages = with pkgs; [
      (mkIf cfg.packages.rofi.enable rofi)
      (mkIf cfg.packages.rofi.enable rofi-power-menu)
      (mkIf cfg.packages.waybar.enable waybar)
      (mkIf cfg.packages.dunst.enable dunst)
      (mkIf cfg.packages.wl-clipboard.enable wl-clipboard)
      (mkIf cfg.packages.grimblast.enable grimblast)
      # Additional Wayland utilities
      (mkIf cfg.enable wlr-randr)
      (mkIf cfg.enable xdg-utils)
      (mkIf cfg.enable grim)
      (mkIf cfg.enable slurp)
    ];

    # Rofi declarative configuration
    programs.rofi = mkIf cfg.packages.rofi.enable {
      enable = true;
      theme = cfg.rofi.theme;
    };

    # Symlink configuration files from dotfiles if they exist
    home.file = mkMerge [
      # Hyprland config
      (mkIf cfg.packages.hyprland.enable {
        ".config/hypr" = {
          source = config.lib.file.mkOutOfStoreSymlink "${cfg.dotfilesPath}/config/hypr";
        };
      })

      # Waybar config
      (mkIf cfg.packages.waybar.enable {
        ".config/waybar" = {
          source = config.lib.file.mkOutOfStoreSymlink "${cfg.dotfilesPath}/config/waybar";
        };
      })

      # Dunst config
      (mkIf cfg.packages.dunst.enable {
        ".config/dunst" = {
          source = config.lib.file.mkOutOfStoreSymlink "${cfg.dotfilesPath}/config/dunst";
        };
      })
    ];

    # Wayland session variables
    home.sessionVariables = mkIf cfg.enable {
      # Wayland-specific environment variables
      MOZ_ENABLE_WAYLAND = "1";
      QT_QPA_PLATFORM = "wayland";
      SDL_VIDEODRIVER = "wayland";
      _JAVA_AWT_WM_NONREPARENTING = "1";
      XDG_SESSION_TYPE = "wayland";
    };
  };
}
