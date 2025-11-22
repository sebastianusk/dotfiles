{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/system/development.nix
    ../../modules/system/fonts.nix
    ../../modules/system/base-utils.nix
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

  # Enable shell system-wide
  programs.zsh.enable = true;
  programs.bash.enable = true;

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

  # Enable system modules
  modules.system = {
    development.enable = true;
    fonts.enable = true;
    base-utils.enable = true;
  };

  # Use latest kernel
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  users.users.deck = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    initialPassword = "deck";
    shell = pkgs.zsh;  # Set zsh as default shell
  };

  networking.networkmanager.enable = true;
  services.openssh.enable = true;
  nixpkgs.config.allowUnfree = true;

  system.stateVersion = "24.05";
}
