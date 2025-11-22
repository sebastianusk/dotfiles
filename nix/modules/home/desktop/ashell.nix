{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.desktop.ashell;

  # Generate TOML configuration
  tomlFormat = pkgs.formats.toml {};

  ashellConfig = {
    bar = {
      position = cfg.bar.position;
      height = cfg.bar.height;
      exclusive_zone = cfg.bar.exclusiveZone;
    };

    appearance = {
      background = cfg.appearance.background;
      foreground = cfg.appearance.foreground;
    };

    # Left modules
    left = cfg.modules.left;

    # Center modules
    center = cfg.modules.center;

    # Right modules
    right = cfg.modules.right;

    # Module configurations
    modules = cfg.moduleConfig;
  };

  configFile = tomlFormat.generate "ashell-config.toml" ashellConfig;
in
{
  options.modules.desktop.ashell = {
    enable = mkEnableOption "ashell - Wayland status bar with built-in widgets";

    package = mkOption {
      type = types.package;
      default = pkgs.ashell;
      description = "ashell package to use";
    };

    bar = {
      position = mkOption {
        type = types.enum [ "top" "bottom" "left" "right" ];
        default = "top";
        description = "Bar position on screen";
      };

      height = mkOption {
        type = types.int;
        default = 32;
        description = "Bar height in pixels";
      };

      exclusiveZone = mkOption {
        type = types.bool;
        default = true;
        description = "Reserve space for the bar";
      };
    };

    appearance = {
      background = mkOption {
        type = types.str;
        default = "#1e1e2e";
        description = "Background color (hex or rgba)";
      };

      foreground = mkOption {
        type = types.str;
        default = "#cdd6f4";
        description = "Foreground color (hex or rgba)";
      };
    };

    modules = {
      left = mkOption {
        type = types.listOf types.attrs;
        default = [
          { type = "Workspaces"; }
          { type = "WindowTitle"; }
        ];
        description = "Modules displayed on the left side";
      };

      center = mkOption {
        type = types.listOf types.attrs;
        default = [
          {
            type = "Clock";
            config.format = "%a %b %d  %H:%M";
          }
        ];
        description = "Modules displayed in the center";
      };

      right = mkOption {
        type = types.listOf types.attrs;
        default = [
          { type = "MediaPlayer"; }
          { type = "Tray"; }
          { type = "Settings"; }
        ];
        description = "Modules displayed on the right side";
      };
    };

    moduleConfig = mkOption {
      type = types.attrs;
      default = {
        Workspaces = {
          show_empty = true;
        };
        Clock = {
          tooltip_format = "%Y %B";
        };
        Settings = {
          show_audio = true;
          show_network = true;
          show_bluetooth = true;
          show_battery = true;
          show_power = true;
        };
      };
      description = "Configuration for individual modules";
    };

    runAsService = mkOption {
      type = types.bool;
      default = true;
      description = "Run ashell as a systemd user service";
    };
  };

  config = mkIf cfg.enable {
    # Install ashell
    home.packages = [ cfg.package ];

    # Generate configuration file
    home.file.".config/ashell".source = configFile;

    # Systemd service for ashell
    systemd.user.services.ashell = mkIf cfg.runAsService {
      Unit = {
        Description = "ashell - Wayland status bar";
        Documentation = "https://malpenzibo.github.io/ashell/";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };

      Service = {
        Type = "simple";
        ExecStart = "${cfg.package}/bin/ashell";
        Restart = "on-failure";
        RestartSec = 3;
        KillMode = "mixed";
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
