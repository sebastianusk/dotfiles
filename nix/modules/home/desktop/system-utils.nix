{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.desktop.systemUtils;
in
{
  options.modules.desktop.systemUtils = {
    enable = mkEnableOption "system utilities for desktop environment";

    networkManager = mkOption {
      type = types.bool;
      default = true;
      description = "Install NetworkManager applet for system tray";
    };

    bluetooth = mkOption {
      type = types.bool;
      default = true;
      description = "Install Blueman bluetooth manager";
    };

    audio = mkOption {
      type = types.bool;
      default = true;
      description = "Install PulseAudio/PipeWire volume control (pavucontrol)";
    };

    brightness = mkOption {
      type = types.bool;
      default = true;
      description = "Install brightness control tools (brightnessctl)";
    };

    systemMonitor = mkOption {
      type = types.enum [ "btop" "htop" "both" "none" ];
      default = "btop";
      description = "System monitor to install";
    };

    powerManagement = mkOption {
      type = types.bool;
      default = true;
      description = "Install power management tools (powertop, tlp)";
    };

    wallpaper = mkOption {
      type = types.enum [ "hyprpaper" "swww" "swaybg" "none" ];
      default = "hyprpaper";
      description = "Wallpaper setter for Wayland";
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      # Network management
      (mkIf cfg.networkManager networkmanagerapplet)

      # Bluetooth
      (mkIf cfg.bluetooth blueman)

      # Audio control
      (mkIf cfg.audio pavucontrol)
      (mkIf cfg.audio playerctl)  # Media player control

      # Brightness control
      (mkIf cfg.brightness brightnessctl)

      # System monitors
      (mkIf (cfg.systemMonitor == "btop" || cfg.systemMonitor == "both") btop)
      (mkIf (cfg.systemMonitor == "htop" || cfg.systemMonitor == "both") htop)

      # Power management
      (mkIf cfg.powerManagement powertop)

      # Wallpaper setters
      (mkIf (cfg.wallpaper == "hyprpaper") hyprpaper)
      (mkIf (cfg.wallpaper == "swww") swww)
      (mkIf (cfg.wallpaper == "swaybg") swaybg)
    ];
  };
}
