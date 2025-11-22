{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.desktop;
in
{
  imports = [
    ./wayland.nix
    ./apps.nix
    ./media.nix
    ./system-utils.nix
    ./themes.nix
  ];

  options.modules.desktop = {
    enable = mkEnableOption "desktop environment with GUI applications and utilities";

    dotfilesPath = mkOption {
      type = types.str;
      default = "${config.home.homeDirectory}/dotfiles";
      description = "Path to dotfiles repository";
    };
  };

  config = mkIf cfg.enable {
    # Enable wayland environment by default when desktop is enabled
    modules.wayland.enable = mkDefault true;
    modules.wayland.dotfilesPath = cfg.dotfilesPath;
  };
}
