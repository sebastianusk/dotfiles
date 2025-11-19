# Zsh Aliases Configuration

# Command Replacements
# alias ls='eza'
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
alias kctx='kubectl-ctx'
alias kns='kubectl-ns'
alias kcm='kubectl-kc'

alias gcm='git commit -m'
alias gpu='git push -u origin HEAD'
