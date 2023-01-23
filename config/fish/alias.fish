alias pingg="ping google.com"
alias ls="exa"
alias cat="bat -p"
alias vim="nvim"
alias diff="delta"
alias random="date | md5sum"
alias dig="dog"
alias curl="curlie"
alias tree="broot"

# for tmuxinator
alias tx=tmuxinator
alias coding="tx start coding"
alias dotfiles="tx start dotfiles"
alias vsplit="tx start vsplit"
alias hsplit="tx start hsplit"

abbr --add kctx kubectx
abbr --add kns kubens

alias docker-cleanup="docker ps --filter "status=exited" | grep 'weeks ago' | awk '{print $1}' | xargs --no-run-if-empty docker rm"
