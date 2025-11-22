{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.terminal.starship;
  terminalCfg = config.modules.terminal;
in
{
  options.modules.terminal.starship = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Install Starship prompt";
    };
  };

  config = mkIf (terminalCfg.enable && cfg.enable) {
    # Install Starship package
    home.packages = with pkgs; [ starship ];

    # Symlink Starship configuration
    home.file.".config/starship.toml" = {
      source = config.lib.file.mkOutOfStoreSymlink "${terminalCfg.dotfilesPath}/config/starship/starship.toml";
    };
  };
}
