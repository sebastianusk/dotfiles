{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.terminal.neovim;
  terminalCfg = config.modules.terminal;
in
{
  options.modules.terminal.neovim = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Install Neovim editor";
    };
  };

  config = mkIf (terminalCfg.enable && cfg.enable) {
    # Install Neovim package
    home.packages = with pkgs; [ neovim ];

    # Symlink our custom Neovim configuration
    home.file.".config/nvim" = {
      source = config.lib.file.mkOutOfStoreSymlink "${terminalCfg.dotfilesPath}/config/nvim";
    };
  };
}
