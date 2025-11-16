# Environment Variables Configuration
# Generated from config/env/base.yaml

# XDG Base Directory Specification
export XDG_CONFIG_HOME="$HOME/.config"

# Basic environment variables
export EDITOR="nvim"
export VISUAL="nvim"
export PAGER="bat"
export BROWSER="open -a 'Google Chrome'"
export CHROME_EXECUTABLE="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
export DISPLAY=":0.0"
export LC_CTYPE="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
export DOCKER_DEFAULT_PLATFORM="linux/amd64"
export PIP_REQUIRE_VIRTUALENV="true"

# Tool configurations will be handled by individual tool initializations

# You Should Use plugin configuration (optional)
export YSU_MESSAGE_POSITION="after"  # Show message after command execution

# Project directories
export CODE="$HOME/Code"
export GOPATH="$CODE/go"

# PATH configuration (prepend to existing PATH)
path_dirs=(
    "/opt/homebrew/bin"
    "/opt/homebrew/sbin"
    "$HOME/.local/share/nvim/mason/bin"
    "$HOME/.local/bin"
    "$HOME/.cargo/bin"
    "$HOME/dotfiles/bin"
    "$GOPATH/bin"
    "$HOME/.krew/bin"
    "$HOME/.pub-cache/bin"
    "/usr/lib/node_modules/.bin"
    "/opt/homebrew/opt/mysql-client/bin"
    "/opt/homebrew/opt/libpq/bin"
    "/Applications/Pritunl.app/Contents/Resources"
)

# Add directories to PATH if they exist
for dir in "${path_dirs[@]}"; do
    [[ -d "$dir" ]] && export PATH="$dir:$PATH"
done

# Dynamic variables
export GPG_TTY=$(tty)
