{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.terminal.alacritty;
  terminalCfg = config.modules.terminal;
in
{
  options.modules.terminal.alacritty = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Install Alacritty terminal emulator";
    };
  };

  config = mkIf (terminalCfg.enable && cfg.enable) {
    # Install Alacritty package
    home.packages = with pkgs; [ alacritty ];

    # Symlink Alacritty configuration
    home.file.".config/alacritty" = {
      source = config.lib.file.mkOutOfStoreSymlink "${terminalCfg.dotfilesPath}/config/alacritty";
    };
  };
}
