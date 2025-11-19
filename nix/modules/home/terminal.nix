{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.terminal;
in
{
  options.modules.terminal = {
    enable = mkEnableOption "terminal environment with essential tools";

    dotfilesPath = mkOption {
      type = types.str;
      default = "${config.home.homeDirectory}/dotfiles";
      description = "Path to dotfiles repository";
    };

    packages = {
      alacritty.enable = mkOption {
        type = types.bool;
        default = true;
        description = "Install Alacritty terminal emulator";
      };

      zsh.enable = mkOption {
        type = types.bool;
        default = true;
        description = "Install and configure Zsh shell";
      };

      tmux.enable = mkOption {
        type = types.bool;
        default = true;
        description = "Install tmux terminal multiplexer";
      };

      neovim.enable = mkOption {
        type = types.bool;
        default = true;
        description = "Install Neovim editor";
      };

      starship.enable = mkOption {
        type = types.bool;
        default = true;
        description = "Install Starship prompt";
      };

      fzf.enable = mkOption {
        type = types.bool;
        default = true;
        description = "Install fzf fuzzy finder";
      };

      atuin.enable = mkOption {
        type = types.bool;
        default = true;
        description = "Install atuin shell history tool";
      };

      zinit.enable = mkOption {
        type = types.bool;
        default = true;
        description = "Install zinit plugin manager for zsh";
      };
    };
  };

  config = mkIf cfg.enable {
    # User packages - install packages without Home Manager's declarative config
    # since we're using our own dotfiles via symlinks
    home.packages = with pkgs; [
      (mkIf cfg.packages.alacritty.enable alacritty)
      (mkIf cfg.packages.tmux.enable tmux)
      (mkIf cfg.packages.neovim.enable neovim)
      (mkIf cfg.packages.starship.enable starship)
      (mkIf cfg.packages.fzf.enable fzf)
      (mkIf cfg.packages.atuin.enable atuin)
      (mkIf cfg.packages.zinit.enable zinit)
    ];

    # Zsh - needs programs.zsh.enable for proper shell integration
    # but we move HM-generated files to avoid conflict with our .zshrc
    programs.zsh = mkIf cfg.packages.zsh.enable {
      enable = true;
      dotDir = ".config/zsh";  # Move HM-generated files out of the way
    };

    # Symlink configuration files from dotfiles
    home.file = mkMerge [
      # Alacritty config
      (mkIf cfg.packages.alacritty.enable {
        ".config/alacritty" = {
          source = config.lib.file.mkOutOfStoreSymlink "${cfg.dotfilesPath}/config/alacritty";
        };
      })

      # Zsh config
      (mkIf cfg.packages.zsh.enable {
        ".config/zsh/.zshrc" = {
          source = config.lib.file.mkOutOfStoreSymlink "${cfg.dotfilesPath}/config/zsh/zshrc";
        };
      })

      # Tmux config
      (mkIf cfg.packages.tmux.enable {
        ".config/tmux" = {
          source = config.lib.file.mkOutOfStoreSymlink "${cfg.dotfilesPath}/config/tmux";
        };
        ".tmux.conf" = {
          source = config.lib.file.mkOutOfStoreSymlink "${cfg.dotfilesPath}/config/tmux/tmux.conf";
        };
      })

      # Neovim config
      (mkIf cfg.packages.neovim.enable {
        ".config/nvim" = {
          source = config.lib.file.mkOutOfStoreSymlink "${cfg.dotfilesPath}/config/nvim";
        };
      })

      # Starship config
      (mkIf cfg.packages.starship.enable {
        ".config/starship.toml" = {
          source = config.lib.file.mkOutOfStoreSymlink "${cfg.dotfilesPath}/config/starship/starship.toml";
        };
      })
    ];
  };
}
