{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.games;
in
{
  options.modules.games = {
    enable = mkEnableOption "gaming applications and tools";

    retroarch = mkOption {
      type = types.bool;
      default = true;
      description = "Install RetroArch - multi-system emulator";
    };

    chiaki = mkOption {
      type = types.bool;
      default = true;
      description = "Install Chiaki-ng - PlayStation Remote Play client";
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      # Emulators
      (mkIf cfg.retroarch retroarch)

      # Remote play
      (mkIf cfg.chiaki chiaki-ng)
    ];
  };
}
