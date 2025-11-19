{ config, pkgs, ... }:

{
  imports = [
    ../../modules/home/terminal.nix
  ];

  # Enable terminal environment
  modules.terminal.enable = true;

  # User packages
  home.packages = with pkgs; [
    firefox
    rofi
    rofi-power-menu
    claude-code
    kitty
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

    rofi = {
      enable = true;
      theme = "gruvbox-dark";
    };
  };
}
