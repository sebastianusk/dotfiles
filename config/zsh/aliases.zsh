# Zsh Aliases Configuration

# Command Replacements
alias ls='eza'
alias cat='bat -p'
alias vim='nvim'
alias diff='delta'
alias curl='curlie'
alias tree='broot'

# Utility Aliases
alias pingg='ping google.com'
alias random='pwgen -c -n -1 -s'

# Container Management
alias docker-cleanup='docker container prune --filter "until=168h"'

# Kubernetes Quick Commands
alias kctx='kubectl config use-context'
alias kns='kubectl config set-context --current --namespace'
alias kcm='kubectl config get-contexts'