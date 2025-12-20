{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.desktop.ashell;

  # Generate TOML configuration
  tomlFormat = pkgs.formats.toml {};

  ashellConfig = {
    log_level = cfg.logLevel;

    outputs = {
      Targets = cfg.outputs.targets;
    };

    position = cfg.position;
    app_launcher_cmd = cfg.appLauncherCmd;

    modules = {
      left = cfg.modules.left;
      center = cfg.modules.center;
      right = cfg.modules.right;
    };

    updates = mkIf cfg.updates.enable {
      check_cmd = cfg.updates.checkCmd;
      update_cmd = cfg.updates.updateCmd;
    };

    workspaces = mkIf cfg.workspaces.enable {
      enable_workspace_filling = cfg.workspaces.enableWorkspaceFilling;
    };

    CustomModule = cfg.customModules;

    window_title = mkIf cfg.windowTitle.enable {
      truncate_title_after_length = cfg.windowTitle.truncateTitleAfterLength;
    };

    settings = {
      lock_cmd = cfg.settings.lockCmd;
      audio_sinks_more_cmd = cfg.settings.audioSinksMoreCmd;
      audio_sources_more_cmd = cfg.settings.audioSourcesMoreCmd;
      wifi_more_cmd = cfg.settings.wifiMoreCmd;
      vpn_more_cmd = cfg.settings.vpnMoreCmd;
      bluetooth_more_cmd = cfg.settings.bluetoothMoreCmd;
    };

    appearance = {
      style = cfg.appearance.style;
      primary_color = cfg.appearance.primaryColor;
      success_color = cfg.appearance.successColor;
      text_color = cfg.appearance.textColor;
      workspace_colors = cfg.appearance.workspaceColors;
      special_workspace_colors = cfg.appearance.specialWorkspaceColors;

      danger_color = {
        base = cfg.appearance.dangerColor.base;
        weak = cfg.appearance.dangerColor.weak;
      };

      background_color = {
        base = cfg.appearance.backgroundColor.base;
        weak = cfg.appearance.backgroundColor.weak;
        strong = cfg.appearance.backgroundColor.strong;
      };

      secondary_color = {
        base = cfg.appearance.secondaryColor.base;
      };
    };
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

    logLevel = mkOption {
      type = types.enum [ "trace" "debug" "info" "warn" "error" ];
      default = "warn";
      description = "Log level for ashell";
    };

    outputs = {
      targets = mkOption {
        type = types.listOf types.str;
        default = [ "eDP-1" ];
        description = "List of output displays to show the bar on";
      };
    };

    position = mkOption {
      type = types.enum [ "Top" "Bottom" "Left" "Right" ];
      default = "Top";
      description = "Bar position on screen";
    };

    appLauncherCmd = mkOption {
      type = types.str;
      default = "rofi -show drun";
      description = "Command to launch application launcher";
    };

    modules = {
      left = mkOption {
        type = types.listOf (types.either types.str (types.listOf types.str));
        default = [ [ "appLauncher" "Workspaces" ] ];
        description = "Modules displayed on the left side";
      };

      center = mkOption {
        type = types.listOf types.str;
        default = [ "WindowTitle" ];
        description = "Modules displayed in the center";
      };

      right = mkOption {
        type = types.listOf (types.either types.str (types.listOf types.str));
        default = [ "SystemInfo" [ "Tray" "Clock" "Privacy" "Settings" ] ];
        description = "Modules displayed on the right side";
      };
    };

    updates = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable updates module";
      };

      checkCmd = mkOption {
        type = types.str;
        default = "";
        description = "Command to check for updates";
      };

      updateCmd = mkOption {
        type = types.str;
        default = "";
        description = "Command to run updates";
      };
    };

    workspaces = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable workspaces configuration";
      };

      enableWorkspaceFilling = mkOption {
        type = types.bool;
        default = true;
        description = "Enable workspace filling";
      };
    };

    customModules = mkOption {
      type = types.listOf types.attrs;
      default = [{
        name = "appLauncher";
        icon = "󱗼";
        command = "rofi -show drun";
      }];
      description = "Custom module definitions";
    };

    windowTitle = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable window title configuration";
      };

      truncateTitleAfterLength = mkOption {
        type = types.int;
        default = 100;
        description = "Truncate window title after this many characters";
      };
    };

    settings = {
      lockCmd = mkOption {
        type = types.str;
        default = "playerctl --all-players pause; hyprctl dispatch dpms off";
        description = "Command to lock the screen";
      };

      audioSinksMoreCmd = mkOption {
        type = types.str;
        default = "pavucontrol -t 3";
        description = "Command to open audio sinks settings";
      };

      audioSourcesMoreCmd = mkOption {
        type = types.str;
        default = "pavucontrol -t 4";
        description = "Command to open audio sources settings";
      };

      wifiMoreCmd = mkOption {
        type = types.str;
        default = "nm-connection-editor";
        description = "Command to open WiFi settings";
      };

      vpnMoreCmd = mkOption {
        type = types.str;
        default = "nm-connection-editor";
        description = "Command to open VPN settings";
      };

      bluetoothMoreCmd = mkOption {
        type = types.str;
        default = "blueman-manager";
        description = "Command to open Bluetooth settings";
      };
    };

    appearance = {
      style = mkOption {
        type = types.str;
        default = "Islands";
        description = "Visual style for the bar";
      };

      primaryColor = mkOption {
        type = types.str;
        default = "#7aa2f7";
        description = "Primary theme color";
      };

      successColor = mkOption {
        type = types.str;
        default = "#9ece6a";
        description = "Success color";
      };

      textColor = mkOption {
        type = types.str;
        default = "#a9b1d6";
        description = "Text color";
      };

      workspaceColors = mkOption {
        type = types.listOf types.str;
        default = [ "#7aa2f7" "#9ece6a" ];
        description = "Colors for workspace indicators";
      };

      specialWorkspaceColors = mkOption {
        type = types.listOf types.str;
        default = [ "#7aa2f7" "#9ece6a" ];
        description = "Colors for special workspace indicators";
      };

      dangerColor = {
        base = mkOption {
          type = types.str;
          default = "#f7768e";
          description = "Base danger color";
        };

        weak = mkOption {
          type = types.str;
          default = "#e0af68";
          description = "Weak danger color";
        };
      };

      backgroundColor = {
        base = mkOption {
          type = types.str;
          default = "#1a1b26";
          description = "Base background color";
        };

        weak = mkOption {
          type = types.str;
          default = "#24273a";
          description = "Weak background color";
        };

        strong = mkOption {
          type = types.str;
          default = "#414868";
          description = "Strong background color";
        };
      };

      secondaryColor = {
        base = mkOption {
          type = types.str;
          default = "#0c0d14";
          description = "Secondary color";
        };
      };
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
    home.file.".config/ashell/config.toml".source = configFile;

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
