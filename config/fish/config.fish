set fish_greeting ""

set -gx VAULT_ADDR https://vault.infra.fazz.id
set -gx CODE ~/Code
set -gx GOPATH $CODE/go
set -gx JDK_HOME /Applications/Android Studio.app/Contents/jre/Contents/Home
set -gx JAVA_HOME $JDK_HOME
set -gx EDITOR 'nvim'
set -gx VISUAL 'nvim'
set -gx PAGER 'bat'
set -gx BROWSER 'vivaldi-stable'
set -gx CHROME_EXECUTABLE 'vivaldi-stable'

set -gx FZF_DEFAULT_OPTS "
    --layout=reverse
    --info=inline
    --height=70%
    --preview-window=:hidden
    --preview '([[ -f {} ]] && (bat --style=numbers --color=always {} || cat {})) || ([[ -d {} ]] && (tree -C {} | less)) || echo {} 2> /dev/null | head -200'
    --preview-window=right:60%:wrap
    --bind '?:toggle-preview'
"
set -gx FZF_DEFAULT_COMMAND "rg --files --hidden"
set -gx FZF_CTRL_T_COMMAND "$FZF_DEFAULT_COMMAND"
set -gx GPG_TTY (tty)

source /opt/homebrew/opt/asdf/libexec/asdf.fish

fish_add_path -p $GOPATH/bin $HOME/.local/bin $HOME/.krew/bin /usr/lib/node_modules/.bin $HOME/.pub-cache/bin $HOME/.deno/bin /Applications/Pritunl.app/Contents/Resources

fish_vi_key_bindings
