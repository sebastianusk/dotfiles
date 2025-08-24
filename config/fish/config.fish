set fish_greeting ""

# Source generated base environment (includes secrets)
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

if type -q starship
    starship init fish --print-full-init | source
end

if test "$MULTIPLEXER" = "tmux"; and not set -q TMUX
    set -g TMUX tmux new-session -d -s base
    eval $TMUX
    tmux attach-session -d -t base
else if test "$MULTIPLEXER" = "zellij"; and status is-interactive; and not set -q ZELLIJ
    # zellij
end
