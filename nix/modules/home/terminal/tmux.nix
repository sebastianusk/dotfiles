{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.terminal.tmux;
  terminalCfg = config.modules.terminal;
in
{
  options.modules.terminal.tmux = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Install tmux terminal multiplexer";
    };

    tmuxinator.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Install and configure tmuxinator session manager";
    };

    tpm.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Install and manage Tmux Plugin Manager (TPM)";
    };
  };

  config = mkIf (terminalCfg.enable && cfg.enable) {
    # Install tmux package and optionally tmuxinator
    home.packages = with pkgs; [
      tmux
      (mkIf cfg.tmuxinator.enable tmuxinator)
    ];

    # Symlink tmux configuration
    home.file = mkMerge [
      {
        ".config/tmux" = {
          source = config.lib.file.mkOutOfStoreSymlink "${terminalCfg.dotfilesPath}/config/tmux";
        };
        ".tmux.conf" = {
          source = config.lib.file.mkOutOfStoreSymlink "${terminalCfg.dotfilesPath}/config/tmux/tmux.conf";
        };
      }

      # Symlink tmuxinator configuration (both locations for compatibility)
      (mkIf cfg.tmuxinator.enable {
        ".config/tmuxinator" = {
          source = config.lib.file.mkOutOfStoreSymlink "${terminalCfg.dotfilesPath}/config/tmux/tmuxinator";
        };
        ".tmuxinator" = {
          source = config.lib.file.mkOutOfStoreSymlink "${terminalCfg.dotfilesPath}/config/tmux/tmuxinator";
        };
      })
    ];

    # Activation script to install and update TPM and its plugins
    home.activation = mkIf cfg.tpm.enable {
      installTmuxPlugins = lib.hm.dag.entryAfter ["writeBoundary"] ''
        TPM_DIR="${config.home.homeDirectory}/.tmux/plugins/tpm"

        # Install TPM if not present
        if [ ! -d "$TPM_DIR" ]; then
          $DRY_RUN_CMD ${pkgs.git}/bin/git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
          echo "Installed Tmux Plugin Manager (TPM)"
        else
          # Update TPM
          $DRY_RUN_CMD ${pkgs.git}/bin/git -C "$TPM_DIR" pull --quiet
        fi

        # Install/update tmux plugins if TPM is available
        if [ -f "$TPM_DIR/scripts/install_plugins.sh" ]; then
          $DRY_RUN_CMD "$TPM_DIR/scripts/install_plugins.sh" > /dev/null 2>&1 || true
          echo "Tmux plugins installed/updated"
        fi
      '';
    };
  };
}
