# Zellij Configuration

Terminal multiplexer configuration with environment integration and security-focused design.

## Overview

This directory contains a modular zellij configuration that:
- Integrates with the centralized environment system
- Excludes secrets for security
- Provides vim-like navigation keybindings
- Uses a clean, simplified UI

## Files

- `zellij.kdl` - Base zellij configuration (version controlled)
- `config.kdl` - Generated final configuration (git-ignored)
- `sync-env.sh` - Environment synchronization script
- `README.md` - This documentation

## Usage

### Initial Setup
```bash
# Generate configuration from environment
./sync-env.sh
```

### Starting Zellij
```bash
# Start new session
zellij

# Start named session
zellij -s work

# Attach to existing session
zellij attach work
```

### Key Bindings

#### Navigation (Normal Mode)
- `Ctrl h` - Move focus left
- `Ctrl j` - Move focus down  
- `Ctrl k` - Move focus up
- `Ctrl l` - Move focus right

#### Default Zellij Bindings
- `Ctrl p` - Pane mode
- `Ctrl t` - Tab mode
- `Ctrl n` - Resize mode
- `Ctrl s` - Search mode
- `Ctrl o` - Session mode
- `Ctrl q` - Quit

## Configuration Details

### Environment Integration
The configuration automatically includes:
- PATH with all tool directories
- Editor and pager preferences
- Development environment variables
- Tool-specific configurations

### Security Model
**Secrets are intentionally excluded** from zellij configuration:
- API keys are not passed to zellij environment
- Sensitive data remains in shell initialization
- Prevents credential exposure in terminal multiplexer
- Maintains clean separation of concerns

### UI Customization
- Simplified interface for cleaner appearance
- Session name visible in pane frames
- Rounded corners disabled for consistency
- Optimized for development workflows

## Troubleshooting

### Configuration Not Loading
```bash
# Regenerate configuration
./sync-env.sh

# Check for syntax errors
zellij --help
```

### Missing Environment Variables
Environment variables are loaded from:
1. Base environment (`../../base.yaml`)
2. Shell initialization (for secrets)
3. System PATH (preserved)

### Permission Issues
```bash
# Make sync script executable
chmod +x sync-env.sh
```

## Development

### Modifying Configuration
1. Edit `zellij.kdl` for zellij-specific settings
2. Edit `../../base.yaml` for environment variables
3. Run `./sync-env.sh` to regenerate
4. Restart zellij to apply changes

### Adding Keybindings
Add to the `keybinds.normal` section in `zellij.kdl`:
```kdl
bind "Ctrl x" { NewPane; }
```

### Testing Changes
```bash
# Test configuration syntax
zellij --help

# Start with specific config
zellij --config ./config.kdl
```

## Integration

This configuration integrates with:
- **Fish Shell**: Environment variables available in all panes
- **Neovim**: Editor settings and PATH integration
- **Development Tools**: All tools available in PATH
- **FZF**: Search and preview configurations

## Security Notes

- Secrets are loaded in shell, not zellij environment
- Generated config is git-ignored to prevent accidental commits
- API keys and tokens remain in secure shell initialization
- Environment separation maintains security boundaries

## Maintenance

### Regular Tasks
- Run `./sync-env.sh` after environment changes
- Update `zellij.kdl` for new keybindings or UI changes
- Test configuration after major zellij updates

### Backup
Base configuration is version controlled. Generated config can be recreated with `./sync-env.sh`.
