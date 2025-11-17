{ config, pkgs, ... }:

{
  # User packages
  home.packages = with pkgs; [
    alacritty
    firefox
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
