zmodload zsh/zprof
export ZSH=$HOME/.oh-my-zsh
zprof
ZSH_THEME="agnoster"

DISABLE_UNTRACKED_FILES_DIRTY="true"

plugins=(
    git
    z
    aws
    brew
    elixir
    docker
    gradle
    kubectl
    node
    npm 
    osx
    pip
    python
    redis-cli
    ssh-agent
    sudo 
    vscode
    yarn
    vagrant
    ripgrep
)

source $ZSH/oh-my-zsh.sh
source ~/.dotfiles/.secretrc
source ~/.dotfiles/.pathrc
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

DEFAULT_USER=$USER

export CODE=/Users/sebastianuskh/Code
export EDITOR='vim'

export GOPATH=$CODE/go

export ANDROID_HOME=/Users/sebastianuskh/Library/Android/sdk

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# export NVM_DIR="$HOME/.nvm"
# [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
# [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

export DOCKER_ID_USER="sebastianuskh"
alias docker-cleanup="docker ps --filter "status=exited" | grep 'weeks ago' | awk '{print $1}' | xargs --no-run-if-empty docker rm"

alias pingg="ping google.com"
alias random="date |md5 "
alias pf-vpn="sudo openvpn ~/Documents/vpn/payfazz-prod.ovpn"

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

export FZF_DEFAULT_OPTS='--height=70% --preview="cat {}" --preview-window=right:60%:wrap'
export FZF_DEFAULT_COMMAND='rg --files'
export FZF_CTRL_T_COMMAND='$FZF_DEFAULT_COMMAND'

