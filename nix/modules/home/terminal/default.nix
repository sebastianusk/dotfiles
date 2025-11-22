{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.terminal;
in
{
  imports = [
    ./zsh.nix
    ./neovim.nix
    ./tmux.nix
    ./alacritty.nix
    ./starship.nix
  ];

  options.modules.terminal = {
    enable = mkEnableOption "terminal environment with essential tools";

    dotfilesPath = mkOption {
      type = types.str;
      default = "${config.home.homeDirectory}/dotfiles";
      description = "Path to dotfiles repository";
    };
  };

  config = mkIf cfg.enable {
    # Common terminal tools
    home.packages = with pkgs; [
      fzf
      atuin
      zoxide
      ripgrep
      fd
      bat
      eza
      broot
    ];
  };
}
