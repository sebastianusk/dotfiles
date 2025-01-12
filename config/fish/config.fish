set fish_greeting ""

source ~/.config/fish/alias.fish
source ~/.config/fish/funct.fish
source ~/.config/fish/opts.fish

set -gx VAULT_ADDR https://vault.infra.fazz.cloud
set -gx CODE ~/Code
set -gx GOPATH $CODE/go
set -gx JDK_HOME /Applications/Android Studio.app/Contents/jre/Contents/Home
set -gx JAVA_HOME $JDK_HOME
set -gx EDITOR 'nvim'
set -gx VISUAL 'nvim'
set -gx PAGER 'bat'
set -gx BROWSER 'brave'
set -gx CHROME_EXECUTABLE 'brave'
set -gx SHELL (which fish)
set -gx DISPLAY ':0.0'
set -gx LC_CTYPE 'en_US.UTF-8'
set -gx LC_ALL 'en_US.UTF-8'
set -gx DOCKER_HOST 'tcp://devbox:2375'
set -gx DOCKER_DEFAULT_PLATFORM 'linux/amd64'

fish_add_path -p $GOPATH/bin $HOME/.local/bin $HOME/.krew/bin /usr/lib/node_modules/.bin $HOME/.pub-cache/bin $HOME/.cargo/bin /opt/homebrew/opt/mysql-client/bin $HOME/.local/share/nvim/mason/bin $HOME/dotfiles/bin /opt/homebrew/sbin /Applications/Pritunl.app/Contents/Resources

if type -q brew
    fish_add_path /opt/homebrew/bin
    source $(brew --prefix asdf)/libexec/asdf.fish
else
    source /opt/asdf-vm/asdf.fish
end

set -gx PIPX_DEFAULT_PYTHON $(asdf which python)
set -gx PIP_REQUIRE_VIRTUALENV true

fish_vi_key_bindings

if type -q starship
    starship init fish --print-full-init | source
end

if not set -q TMUX
    set -g TMUX tmux new-session -d -s base
    eval $TMUX
    tmux attach-session -d -t base
end

fish_add_path /opt/homebrew/opt/libpq/bin
