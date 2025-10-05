alias pingg="ping google.com"
alias ls="eza"
alias cat="bat -p"
alias vim="nvim"
alias diff="delta"
alias random="pwgen -c -n -1 -s"
alias curl="curlie"
alias tree="broot"
alias grep="grep -i"

# goose configuration sync
alias sync-goose="~/dotfiles/sync-goose.sh"

abbr --add kctx kubectl-ctx
abbr --add kns kubectl-ns
abbr --add kcm kubectl-kc

alias docker-cleanup="docker ps --filter "status=exited" | grep 'weeks ago' | awk '{print $1}' | xargs --no-run-if-empty docker rm"
