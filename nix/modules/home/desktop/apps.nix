{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.desktop.apps;
in
{
  options.modules.desktop.apps = {
    enable = mkEnableOption "GUI applications for desktop environment";

    browsers = mkOption {
      type = types.listOf (types.enum [ "firefox" "chromium" "brave" "tor" ]);
      default = [ "firefox" ];
      description = "Web browsers to install";
    };

    defaultBrowser = mkOption {
      type = types.enum [ "firefox" "chromium" "brave" "none" ];
      default = "firefox";
      description = "Default web browser";
    };

    fileManager = mkOption {
      type = types.enum [ "thunar" "nautilus" "nemo" "none" ];
      default = "thunar";
      description = "File manager to install";
    };

    imageViewer = mkOption {
      type = types.enum [ "imv" "feh" "nsxiv" "none" ];
      default = "imv";
      description = "Image viewer to install";
    };

    pdfViewer = mkOption {
      type = types.enum [ "zathura" "evince" "okular" "none" ];
      default = "zathura";
      description = "PDF viewer to install";
    };

    archiveManager = mkOption {
      type = types.bool;
      default = true;
      description = "Install archive manager (file-roller)";
    };

    colorPicker = mkOption {
      type = types.bool;
      default = true;
      description = "Install Hyprpicker color picker for Wayland";
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      # Browsers
      (mkIf (elem "chromium" cfg.browsers) chromium)
      (mkIf (elem "brave" cfg.browsers) brave)
      (mkIf (elem "tor" cfg.browsers) tor-browser-bundle-bin)

      # File managers
      (mkIf (cfg.fileManager == "thunar") xfce.thunar)
      (mkIf (cfg.fileManager == "nautilus") gnome.nautilus)
      (mkIf (cfg.fileManager == "nemo") cinnamon.nemo)

      # Image viewers
      (mkIf (cfg.imageViewer == "imv") imv)
      (mkIf (cfg.imageViewer == "feh") feh)
      (mkIf (cfg.imageViewer == "nsxiv") nsxiv)

      # PDF viewers
      (mkIf (cfg.pdfViewer == "zathura") zathura)
      (mkIf (cfg.pdfViewer == "evince") evince)
      (mkIf (cfg.pdfViewer == "okular") libsForQt5.okular)

      # Archive manager
      (mkIf cfg.archiveManager file-roller)

      # Color picker
      (mkIf cfg.colorPicker hyprpicker)
    ];

    # Firefox configuration
    programs.firefox = mkIf (elem "firefox" cfg.browsers) {
      enable = true;
      profiles.default = {
        id = 0;
        isDefault = true;
        settings = {
          # Privacy settings
          "privacy.donottrackheader.enabled" = true;
          "privacy.trackingprotection.enabled" = true;
          "privacy.trackingprotection.socialtracking.enabled" = true;

          # Performance
          "gfx.webrender.all" = true;
          "media.ffmpeg.vaapi.enabled" = true;
          "widget.dmabuf.force-enabled" = true;

          # Disable pocket
          "extensions.pocket.enabled" = false;

          # Smooth scrolling
          "general.smoothScroll" = true;
        };
      };
    };

    # Zathura configuration
    programs.zathura = mkIf (cfg.pdfViewer == "zathura") {
      enable = true;
      options = {
        selection-clipboard = "clipboard";
        recolor = true;
        recolor-darkcolor = "#ebdbb2";
        recolor-lightcolor = "#282828";
      };
    };

    # Set default browser
    home.sessionVariables = mkIf (cfg.defaultBrowser != "none") {
      BROWSER = cfg.defaultBrowser;
    };

    xdg.mimeApps = mkIf (cfg.defaultBrowser != "none") {
      enable = true;
      defaultApplications = {
        "text/html" = "${cfg.defaultBrowser}.desktop";
        "x-scheme-handler/http" = "${cfg.defaultBrowser}.desktop";
        "x-scheme-handler/https" = "${cfg.defaultBrowser}.desktop";
        "x-scheme-handler/about" = "${cfg.defaultBrowser}.desktop";
        "x-scheme-handler/unknown" = "${cfg.defaultBrowser}.desktop";
      };
    };
  };
}
