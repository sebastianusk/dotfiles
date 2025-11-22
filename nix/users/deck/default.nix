{ config, pkgs, ... }:

{
  imports = [
    ../../modules/terminal  # New directory-based terminal module
    ../../modules/home/wayland.nix
  ];

  # Enable terminal environment
  modules.terminal.enable = true;

  # Enable Wayland desktop environment
  modules.wayland.enable = true;

  # User packages
  home.packages = with pkgs; [
    firefox
    claude-code
  ];

  # Home Manager version
  home.stateVersion = "24.05";

  # Basic programs
  programs = {
    git = {
      enable = true;
      settings = {
        user = {
          name = "deck";
          email = "deck@steamdeck.local";
        };
      };
    };
  };
}
