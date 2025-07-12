# Goose Configuration

This directory contains the complete Goose AI assistant configuration synced from `~/.config/goose/`.

## Files

- `config.yaml` - Main Goose configuration including model settings, provider config, and enabled extensions
- `permission.yaml` - Tool permissions configuration for user and smart_approve modes
- `.gitignore` - Excludes temporary files, history, and user-specific data from version control

## Syncing Configuration

### Automatic Sync (Recommended)
The entire configuration directory is automatically linked via the `setup.sh` script:

```bash
# Run setup to create directory symlink
./setup.sh
```

This creates a symlink from `~/.config/goose` to `~/dotfiles/config/goose`, so any changes are immediately reflected.

### Manual Sync
To manually sync the latest configuration from your live Goose setup to your dotfiles:

```bash
# Using the sync script (copies entire directory)
./sync-goose.sh

# Or using the fish alias (after sourcing alias.fish)
sync-goose
```

### What's Excluded

The `.gitignore` file excludes:
- `history.txt` - Command history (user-specific)
- `*.bak*` - Backup files (temporary)
- `memory/` - User-specific memory data
- Log files and other temporary files

### Current Configuration

- **Model**: Claude Sonnet 4 (claude-sonnet-4-20250514)
- **Provider**: Anthropic
- **Mode**: smart_approve
- **Extensions**: 
  - computercontroller (builtin)
  - context7 (MCP)
  - developer (builtin)
  - fetch (MCP)
  - memory (builtin)
  - tavily (MCP)

## Notes

- The directory symlink approach means changes are automatically reflected
- Use `sync-goose` when you want to update your dotfiles repository with the latest config
- The `.gitignore` file ensures only configuration files are tracked, not user data
- Configuration changes should be made in the live `~/.config/goose/` directory
