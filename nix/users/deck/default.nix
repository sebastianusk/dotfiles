{ config, pkgs, ... }:

{
  # User packages
  home.packages = with pkgs; [
    alacritty
    firefox
    rofi
    rofi-power-menu
    claude-code
  ];

  # Home Manager version
  home.stateVersion = "24.05";

  # Basic programs
  programs = {
    git = {
      enable = true;
      userName = "deck";
      userEmail = "deck@steamdeck.local";
    };

    rofi = {
      enable = true;
      theme = "gruvbox-dark";
    };
  };
}
