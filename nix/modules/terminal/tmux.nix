{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.terminal.tmux;
  terminalCfg = config.modules.terminal;
in
{
  options.modules.terminal.tmux = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Install tmux terminal multiplexer";
    };
  };

  config = mkIf (terminalCfg.enable && cfg.enable) {
    # Install tmux package
    home.packages = with pkgs; [ tmux ];

    # Symlink tmux configuration
    home.file = {
      ".config/tmux" = {
        source = config.lib.file.mkOutOfStoreSymlink "${terminalCfg.dotfilesPath}/config/tmux";
      };
      ".tmux.conf" = {
        source = config.lib.file.mkOutOfStoreSymlink "${terminalCfg.dotfilesPath}/config/tmux/tmux.conf";
      };
    };
  };
}
