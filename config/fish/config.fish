set fish_greeting ""

source ~/.config/fish/alias.fish
source ~/.config/fish/funct.fish
source ~/.config/fish/opts.fish

set -gx VAULT_ADDR https://vault.infra.fazz.id
set -gx CODE ~/Code
set -gx GOPATH $CODE/go
set -gx JDK_HOME /Applications/Android Studio.app/Contents/jre/Contents/Home
set -gx JAVA_HOME $JDK_HOME
set -gx EDITOR 'nvim'
set -gx VISUAL 'nvim'
set -gx PAGER 'bat'
set -gx BROWSER 'brave'
set -gx CHROME_EXECUTABLE 'brave'

fish_add_path -p $GOPATH/bin $HOME/.local/bin $HOME/.krew/bin /usr/lib/node_modules/.bin $HOME/.pub-cache/bin $HOME/.deno/bin

if type -q brew
    fish_add_path /opt/homebrew/bin
    source $(brew --prefix asdf)/libexec/asdf.fish
end

fish_vi_key_bindings

if not set -q TMUX
    set -g TMUX tmux new-session -d -s base
    eval $TMUX
    tmux attach-session -d -t base
end

if type -q starship
    starship init fish --print-full-init | source
end
