{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.system.base-utils;
in
{
  options.modules.system.base-utils = {
    enable = mkEnableOption "essential CLI utilities and system tools";

    monitoring = mkOption {
      type = types.bool;
      default = true;
      description = "Include system monitoring tools (htop, btop, lm_sensors)";
    };

    archives = mkOption {
      type = types.bool;
      default = true;
      description = "Include archive tools (unzip, zip, p7zip)";
    };

    hardware = mkOption {
      type = types.bool;
      default = true;
      description = "Include hardware utilities (pciutils, usbutils)";
    };

    filesystems = mkOption {
      type = types.bool;
      default = true;
      description = "Include filesystem tools (ntfs3g for USB drives)";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      # Essential tools
      git
      vim

      # Basic utilities
      tree
      wget
      curl
      file
      which
      findutils

      # System monitoring (optional)
      (mkIf cfg.monitoring htop)
      (mkIf cfg.monitoring btop)
      (mkIf cfg.monitoring lm_sensors)

      # Archive tools (optional)
      (mkIf cfg.archives unzip)
      (mkIf cfg.archives zip)
      (mkIf cfg.archives p7zip)

      # Hardware utilities (optional)
      (mkIf cfg.hardware pciutils)    # lspci
      (mkIf cfg.hardware usbutils)    # lsusb

      # Filesystem support (optional)
      (mkIf cfg.filesystems ntfs3g)   # NTFS support for USB drives
    ];
  };
}
