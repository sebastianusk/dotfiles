{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.desktop.themes;

  # Color palettes for each theme
  colorPalettes = {
    gruvbox = {
      background = "#282828";
      backgroundAlt = "#3c3836";
      backgroundAlt2 = "#504945";
      foreground = "#ebdbb2";
      primary = "#83a598";      # bright blue
      secondary = "#b8bb26";    # bright green
      accent = "#fabd2f";       # bright yellow
      urgent = "#fb4934";       # bright red
    };
    dracula = {
      background = "#282a36";
      backgroundAlt = "#44475a";
      backgroundAlt2 = "#6272a4";
      foreground = "#f8f8f2";
      primary = "#bd93f9";      # purple
      secondary = "#50fa7b";    # green
      accent = "#ffb86c";       # orange
      urgent = "#ff5555";       # red
    };
    nord = {
      background = "#2e3440";
      backgroundAlt = "#3b4252";
      backgroundAlt2 = "#434c5e";
      foreground = "#eceff4";
      primary = "#88c0d0";      # frost blue
      secondary = "#a3be8c";    # green
      accent = "#ebcb8b";       # yellow
      urgent = "#bf616a";       # red
    };
    catppuccin = {
      background = "#1e1e2e";
      backgroundAlt = "#313244";
      backgroundAlt2 = "#45475a";
      foreground = "#cdd6f4";
      primary = "#89b4fa";      # blue
      secondary = "#a6e3a1";    # green
      accent = "#f9e2af";       # yellow
      urgent = "#f38ba8";       # red
    };
  };

  # Get colors for current theme, fallback to gruvbox
  themeColors = colorPalettes.${cfg.gtkTheme} or colorPalettes.gruvbox;
in
{
  options.modules.desktop.themes = {
    enable = mkEnableOption "desktop themes, icons, and cursors";

    gtkTheme = mkOption {
      type = types.enum [ "gruvbox" "dracula" "nord" "catppuccin" "none" ];
      default = "gruvbox";
      description = "GTK theme to install and configure";
    };

    colors = mkOption {
      type = types.attrs;
      default = themeColors;
      description = "Color palette for the selected theme (auto-generated)";
      readOnly = true;
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
