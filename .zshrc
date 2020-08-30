export ZSH=$HOME/.oh-my-zsh

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

source ~/.dotfiles/.aliasrc
source ~/.dotfiles/.initrc
source ~/.dotfiles/.pathrc
source ~/.dotfiles/.personalrc
source ~/.dotfiles/.secretrc
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

DEFAULT_USER=$USER

export EDITOR='vim'

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

if type nvim > /dev/null 2>&1; then
    alias vim='nvim'
fi
