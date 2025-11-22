{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.desktop.themes;
in
{
  options.modules.desktop.themes = {
    enable = mkEnableOption "desktop themes, icons, and cursors";

    gtkTheme = mkOption {
      type = types.enum [ "gruvbox" "dracula" "nord" "catppuccin" "none" ];
      default = "gruvbox";
      description = "GTK theme to install and configure";
    };

    iconTheme = mkOption {
      type = types.enum [ "papirus" "tela" "numix" "none" ];
      default = "papirus";
      description = "Icon theme to install";
    };

    cursorTheme = mkOption {
      type = types.enum [ "bibata" "breeze" "vanilla" "none" ];
      default = "bibata";
      description = "Cursor theme to install";
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      # GTK themes
      (mkIf (cfg.gtkTheme == "gruvbox") gruvbox-gtk-theme)
      (mkIf (cfg.gtkTheme == "dracula") dracula-theme)
      (mkIf (cfg.gtkTheme == "nord") nordic)
      (mkIf (cfg.gtkTheme == "catppuccin") catppuccin-gtk)

      # Icon themes
      (mkIf (cfg.iconTheme == "papirus") papirus-icon-theme)
      (mkIf (cfg.iconTheme == "tela") tela-icon-theme)
      (mkIf (cfg.iconTheme == "numix") numix-icon-theme)

      # Cursor themes
      (mkIf (cfg.cursorTheme == "bibata") bibata-cursors)
      (mkIf (cfg.cursorTheme == "breeze") libsForQt5.breeze-icons)
    ];

    # GTK configuration
    gtk = mkIf (cfg.gtkTheme != "none") {
      enable = true;
      theme = {
        name =
          if cfg.gtkTheme == "gruvbox" then "Gruvbox-Dark"
          else if cfg.gtkTheme == "dracula" then "Dracula"
          else if cfg.gtkTheme == "nord" then "Nordic"
          else if cfg.gtkTheme == "catppuccin" then "Catppuccin-Mocha"
          else null;
      };
      iconTheme = mkIf (cfg.iconTheme != "none") {
        name =
          if cfg.iconTheme == "papirus" then "Papirus-Dark"
          else if cfg.iconTheme == "tela" then "Tela"
          else if cfg.iconTheme == "numix" then "Numix"
          else null;
      };
      cursorTheme = mkIf (cfg.cursorTheme != "none") {
        name =
          if cfg.cursorTheme == "bibata" then "Bibata-Modern-Classic"
          else if cfg.cursorTheme == "breeze" then "breeze_cursors"
          else if cfg.cursorTheme == "vanilla" then "Vanilla-DMZ"
          else null;
      };
    };
  };
}
