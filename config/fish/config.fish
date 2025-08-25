set fish_greeting ""

# Ensure basic system paths are available first
fish_add_path -p /usr/bin /bin /usr/sbin /sbin

# Source generated base environment (includes secrets and full PATH)
source ~/.config/fish/env.fish

source ~/.config/fish/alias.fish
source ~/.config/fish/funct.fish

# Fish-specific or dynamic environment variables
set -gx VAULT_ADDR https://vault.infra.fazz.cloud
set -gx SHELL (which fish)
set -gx DOCKER_HOST 'tcp://devbox:2375'

# ASDF integration (dynamic)
if type -q brew
    source $(brew --prefix asdf)/libexec/asdf.fish
else
    source /opt/asdf-vm/asdf.fish
end

set -gx PIPX_DEFAULT_PYTHON $(asdf which python)

# Fish-specific features
fish_vi_key_bindings

# Catppuccin Mocha theme activation
if test -f ~/.config/fish/themes/Catppuccin\ Mocha.theme
    fish_config theme choose "Catppuccin Mocha" >/dev/null 2>&1
end

# Custom FZF bindings (load after plugins)
if functions -q fzf_configure_bindings
    fzf_configure_bindings --directory=\ct
end

if type -q starship
    starship init fish --print-full-init | source
end
if status is-interactive
    if test "$MULTIPLEXER" = "tmux"; and not set -q TMUX
        set -g TMUX tmux new-session -d -s base
        eval $TMUX
        tmux attach-session -d -t base
    else if test "$MULTIPLEXER" = "zellij"; and not set -q ZELLIJ
        eval (zellij setup --generate-auto-start fish | string collect)
    end
end
