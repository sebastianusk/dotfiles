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

fzf_configure_bindings --directory=\ct
