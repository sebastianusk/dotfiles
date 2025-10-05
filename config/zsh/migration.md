# Shell Configuration Feature Inventory

This document lists all functionality that needs to be implemented in the new shell configuration.

## Core Shell Features

### Environment Management
- **Centralized YAML Configuration**: Environment variables managed via `../env/base.yaml` and `../env/secret.yaml`
- **Generated Environment Files**: Shell-specific environment files generated from YAML sources
- **Dynamic Variables**: GPG_TTY set dynamically based on current terminal
- **PATH Management**: PATH configuration from YAML with proper ordering

### Shell Behavior
- **Vi Key Bindings**: Vi-style command line editing
- **No Greeting Message**: Suppress shell greeting/welcome messages
- **Interactive Session Detection**: Different behavior for interactive vs non-interactive shells
- **History Configuration**: Enhanced history settings

### Key Environment Variables
- `VAULT_ADDR`: https://vault.infra.fazz.cloud
- `SHELL`: Path to current shell
- `DOCKER_HOST`: tcp://devbox:2375
- `EDITOR`: nvim
- `VISUAL`: nvim
- `PAGER`: bat
- `BROWSER`: chrome
- `CHROME_EXECUTABLE`: chrome
- `DISPLAY`: :0.0
- `LC_CTYPE`: en_US.UTF-8
- `LC_ALL`: en_US.UTF-8
- `DOCKER_DEFAULT_PLATFORM`: linux/amd64
- `PIP_REQUIRE_VIRTUALENV`: true

## Tool Integrations

### Version Managers
- **ASDF Integration**: Load ASDF version manager with fallback logic
  - Check for Homebrew installation first
  - Fallback to /opt/asdf-vm/ if Homebrew not available

### Prompt
- **Starship Prompt**: Modern, fast prompt with git integration
- **Conditional Loading**: Only load if starship is available

### Fuzzy Finder (FZF)
- **Enhanced Configuration**: Layout, preview, and binding customization
- **File Preview**: bat/cat preview for files, tree for directories
- **Custom Bindings**: Directory search on Ctrl+T
- **Default Commands**: Use ripgrep for file finding
- **Preview Window**: Right side, 60% width, toggleable with ?

### Multiplexer Auto-Start
- **Conditional Auto-Start**: Based on MULTIPLEXER environment variable
- **Tmux Support**: Auto-start tmux session named "base"
- **Zellij Support**: Auto-start with zellij setup
- **Interactive Only**: Only start in interactive sessions

### Cloud Tools
- **Google Cloud SDK**: Load Google Cloud SDK path integration
- **AWS CLI**: Profile management and completion
- **Kubectl**: Kubernetes CLI completion

### Other Tools
- **iTerm2 Integration**: Shell integration for iTerm2
- **NVM Integration**: Node Version Manager integration

## Aliases

### Command Replacements
- `ls` → `eza` (modern ls replacement)
- `cat` → `bat -p` (syntax highlighted cat)
- `vim` → `nvim` (Neovim)
- `diff` → `delta` (modern diff viewer)
- `curl` → `curlie` (curl with syntax highlighting)
- `tree` → `broot` (interactive tree viewer)

### Utility Aliases
- `pingg`: ping google.com
- `random`: pwgen -c -n -1 -s (password generation)
 
### Container Management
- `docker-cleanup`: Remove containers that have been exited for weeks

### Quick Commands (Abbreviations)
- `kctx`: kubectl-ctx (Kubernetes context switching)
- `kns`: kubectl-ns (Kubernetes namespace switching)  
- `kcm`: kubectl-kc (Kubernetes config management)

## Custom Functions

### Navigation
- **cdg**: Change directory to git repository root
  - Find git toplevel directory
  - Change to that directory if found

### File Management
- **extract**: Universal archive extraction
  - Support formats: tar, gz, tgz, bz2, rar, zip
  - Automatically detect format from extension
  - Handle compressed tar files appropriately

### Temporary Files
- **tmpa**: Create timestamped temporary file in /tmp/files
  - Create /tmp/files directory if it doesn't exist
  - Generate timestamp-based filename
  - Accept optional file extension parameter
  - Open file in nvim for editing

- **tmpl**: List and edit temporary files
  - List files in /tmp/files
  - Use fzf for selection
  - Open selected file in nvim

### Enhanced Commands
- **sudo**: Enhanced sudo with history support
  - Support `sudo !!` to run last command with sudo
  - Fallback to normal sudo behavior for other arguments

### AWS Management
- **ap**: AWS Profile Selector with SSO
  - Parse AWS config file for profiles
  - Display profile, account ID, and region information
  - Use fzf for interactive selection
  - Validate session and handle SSO login
  - Display current identity information
  - Handle error cases gracefully

### Multiplexer Management
- **vsplit**: Start multiplexer with split layout
  - Support tmux with tmuxinator
  - Support zellij with layout
  - Detect current multiplexer from environment

## Plugin Ecosystem Requirements

### Essential Plugins
- **Git Integration**: Git aliases, status in prompt, completion
- **Directory Jumping**: Frecency-based directory navigation (z/zoxide)
- **SSH Agent Management**: Automatic SSH agent handling
- **Syntax Highlighting**: Command syntax highlighting as you type
- **Auto-suggestions**: Command suggestions based on history
- **FZF Enhanced**: Advanced fuzzy finding integration
- **Auto-pairing**: Automatic bracket/quote pairing
- **AWS/Docker/Kubernetes**: Cloud tool completions and helpers

### Development Tools
- **Node.js/NPM**: Package manager integration
- **Python/Pip**: Python development tools
- **Docker**: Container management helpers
- **Ripgrep**: Fast text searching integration

## Theme and Visual Configuration

### Color Scheme
- **Catppuccin Mocha**: Consistent color theme across tools
- **Conditional Loading**: Only apply if theme files are available

### Prompt Features
- **Git Status**: Branch, changes, ahead/behind information
- **Directory Path**: Current working directory with smart truncation
- **Command Status**: Success/failure indication
- **Execution Time**: Show command duration for long-running commands

## Directory Structure Requirements

### Configuration Files
- Main shell configuration file
- Aliases configuration
- Functions configuration  
- Plugin management
- Environment variables (generated)

### Sync System
- YAML-based environment configuration
- Cross-shell compatibility (Fish, Zsh, Bash)
- Automatic generation of shell-specific files
- Secret management integration

## PATH Configuration

### Priority Order (High to Low)
1. /opt/homebrew/bin
2. /opt/homebrew/sbin
3. $HOME/.local/share/nvim/mason/bin
4. $HOME/.local/bin
5. $HOME/.cargo/bin
6. $HOME/dotfiles/bin
7. $GOPATH/bin
8. $HOME/.krew/bin
9. $HOME/.pub-cache/bin
10. /usr/lib/node_modules/.bin
11. /opt/homebrew/opt/mysql-client/bin
12. /opt/homebrew/opt/libpq/bin
13. /Applications/Pritunl.app/Contents/Resources

### Environment Directories
- `CODE`: $HOME/Code
- `GOPATH`: $CODE/go

## FZF Configuration Requirements

### Default Options
- Reverse layout
- Inline info display
- 70% height
- Hidden preview window by default
- Right-side preview (60% width, wrapped)
- Toggle preview with '?' key

### Preview Commands
- Files: bat with syntax highlighting, fallback to cat
- Directories: tree command with colors
- Default: head -200 for other content types

### Search Commands
- Default: ripgrep with hidden files
- Ctrl+T: Same as default command

## Performance Considerations

### Conditional Loading
- Only load tools that are actually installed
- Graceful fallbacks for missing dependencies
- Fast startup time priority

### Plugin Management
- Lazy loading where possible
- Minimal core configuration
- Plugin-specific optimizations