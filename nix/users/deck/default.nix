{ config, pkgs, ... }:

{
  imports = [
    ../../modules/home/terminal
    ../../modules/home/desktop
  ];

  # Enable terminal environment
  modules.terminal.enable = true;

  # Enable desktop environment (includes Wayland, apps, media, etc.)
  modules.desktop = {
    enable = true;

    # GUI Applications
    apps = {
      enable = true;
      browsers = [ "firefox" ];
      defaultBrowser = "firefox";
      fileManager = "thunar";
      imageViewer = "imv";
      pdfViewer = "zathura";
      archiveManager = true;
      colorPicker = true;
    };

    # Media players and tools
    media = {
      enable = true;
      videoPlayer = "mpv";
      imageTools = true;
      screenRecording = true;
    };

    # System utilities
    systemUtils = {
      enable = true;
      networkManager = true;
      bluetooth = true;
      audio = true;
      brightness = true;
      systemMonitor = "btop";
      powerManagement = true;
      wallpaper = "hyprpaper";
    };

    # Themes and appearance
    themes = {
      enable = true;
      gtkTheme = "gruvbox";
      iconTheme = "papirus";
      cursorTheme = "bibata";
    };
  };

  # User packages
  home.packages = with pkgs; [
    claude-code
  ];

  # Home Manager version
  home.stateVersion = "24.05";

  # Basic programs
  programs = {
    git = {
      enable = true;
      settings = {
        user = {
          name = "deck";
          email = "deck@steamdeck.local";
        };
      };
    };
  };
}
