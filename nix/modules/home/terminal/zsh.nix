{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.terminal.zsh;
  terminalCfg = config.modules.terminal;
in
{
  options.modules.terminal.zsh = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Install and configure Zsh shell with plugins";
    };

    useHomeManagerPlugins = mkOption {
      type = types.bool;
      default = true;
      description = "Use Home Manager's native plugin system instead of zinit";
    };
  };

  config = mkIf (terminalCfg.enable && cfg.enable) {
    programs.zsh = {
      enable = true;

      # Home Manager native plugin system using nixpkgs packages
      # No need to manage versions or hashes - nixpkgs handles it
      plugins = mkIf cfg.useHomeManagerPlugins [
        {
          name = "zsh-syntax-highlighting";
          src = pkgs.zsh-syntax-highlighting;
          file = "share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh";
        }
        {
          name = "zsh-autosuggestions";
          src = pkgs.zsh-autosuggestions;
          file = "share/zsh-autosuggestions/zsh-autosuggestions.zsh";
        }
        {
          name = "zsh-completions";
          src = pkgs.zsh-completions;
        }
        {
          name = "fzf-tab";
          src = pkgs.zsh-fzf-tab;
          file = "share/fzf-tab/fzf-tab.plugin.zsh";
        }
        {
          name = "zsh-you-should-use";
          src = pkgs.zsh-you-should-use;
          file = "share/zsh/plugins/you-should-use/you-should-use.plugin.zsh";
        }
      ];

      # Oh My Zsh integration for snippets
      oh-my-zsh = mkIf cfg.useHomeManagerPlugins {
        enable = true;
        plugins = [
          "git"
          "sudo"
          "archlinux"
          "aws"
          "gcloud"
          "kubectl"
          "kubectx"
          "command-not-found"
        ];
      };

      # Additional zsh configuration
      initContent = mkIf cfg.useHomeManagerPlugins ''
        # Load our custom configuration from dotfiles
        if [[ -f "$HOME/dotfiles/config/zsh/env.zsh" ]]; then
          source "$HOME/dotfiles/config/zsh/env.zsh"
        fi

        if [[ -f "$HOME/dotfiles/config/zsh/secret.zsh" ]]; then
          source "$HOME/dotfiles/config/zsh/secret.zsh"
        fi

        # FZF key bindings
        if command -v fzf >/dev/null 2>&1; then
          eval "$(fzf --zsh)"
        fi

        # Starship prompt
        if command -v starship >/dev/null 2>&1; then
          eval "$(starship init zsh)"
        fi

        # Atuin - Load after FZF to override Ctrl+R
        if command -v atuin >/dev/null 2>&1; then
          eval "$(atuin init zsh --disable-up-arrow)"
        fi

        # Zoxide
        if command -v zoxide >/dev/null 2>&1; then
          eval "$(zoxide init --cmd cd zsh)"
        fi

        # Completion configuration
        zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
        zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"
        zstyle ':completion:*' menu no
        zstyle ':completion:*' completer _expand_alias _complete _ignored
        zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
        zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

        # Multiplexer auto-start (interactive sessions only)
        if [[ $- == *i* ]]; then
          if [[ "$MULTIPLEXER" == "tmux" ]] && [[ -z "$TMUX" ]]; then
            TMUX="tmux new-session -d -s base"
            eval $TMUX
            tmux attach-session -d -t base
          elif [[ "$MULTIPLEXER" == "zellij" ]] && [[ -z "$ZELLIJ" ]]; then
            eval "$(zellij setup --generate-auto-start zsh)"
          fi
        fi

        # Load aliases
        if [[ -f "$HOME/dotfiles/config/zsh/aliases.zsh" ]]; then
          source "$HOME/dotfiles/config/zsh/aliases.zsh"
        fi

        # Emacs keybinding
        bindkey -e
      '';
    };

    # Symlink our custom zshrc for manual zinit setup (when useHomeManagerPlugins = false)
    home.file = mkIf (!cfg.useHomeManagerPlugins) {
      ".config/zsh/.zshrc" = {
        source = config.lib.file.mkOutOfStoreSymlink "${terminalCfg.dotfilesPath}/config/zsh/zshrc";
      };
    };
  };
}
