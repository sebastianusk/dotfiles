export ZSH=$HOME/.oh-my-zsh

export ZSH_THEME=robbyrussell


DISABLE_UNTRACKED_FILES_DIRTY="true"

plugins=(
    git
    z
    aws
    docker
    node
    npm
    osx
    pip
    python
    redis-cli
    ssh-agent
    sudo
    yarn
    ripgrep
)

source $ZSH/oh-my-zsh.sh

include () {
    [[ -f "$1" ]] && source "$1"
}

include ~/dotfiles/.aliasrc
include ~/dotfiles/.initrc
include ~/dotfiles/.pathrc
include ~/dotfiles/.personalrc
include ~/dotfiles/.secretrc

source /usr/share/fzf/key-bindings.zsh
source /usr/share/fzf/completion.zsh

DEFAULT_USER=$USER

export EDITOR='nvim'

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

if type nvim > /dev/null 2>&1; then
    alias vim='nvim'
fi

if [[ $DISPLAY ]]; then
    if [ -z "$TMUX" ]
    then
        tmux new-session
    fi
fi

source <(kubectl completion zsh)
