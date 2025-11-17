{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  jovian = {
    devices.steamdeck = {
      enable = true;
      enableXorgRotation = false;  # Using Wayland
    };
    steam = {
      enable = true;
      autoStart = false;  # Manual launch
      user = "deck";
      desktopSession = "hyprland";  # Switch to Hyprland from gaming mode
    };
  };

  # Hyprland setup
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;  # For Steam games
  };

  # Display manager
  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "${pkgs.hyprland}/bin/Hyprland";
      user = "deck";
    };
  };

  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Essential system tools
  environment.systemPackages = with pkgs; [
    git
    vim
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  users.users.deck = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    initialPassword = "deck";
  };

  networking.networkmanager.enable = true;
  services.openssh.enable = true;
  nixpkgs.config.allowUnfree = true;

  system.stateVersion = "24.05";
}
