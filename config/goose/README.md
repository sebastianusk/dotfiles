# Goose Configuration

This directory contains the Goose AI assistant configuration files that are synced with `~/.config/goose/`.

## Files

- `config.yaml` - Main Goose configuration including model settings, provider config, and enabled extensions
- `permission.yaml` - Tool permissions configuration for user and smart_approve modes

## Syncing Configuration

### Automatic Sync (Recommended)
The configuration files are automatically linked via the `setup.sh` script:

```bash
# Run setup to create symlinks
./setup.sh
```

### Manual Sync
To manually sync the latest configuration from your live Goose setup:

```bash
# Using the sync script
./sync-goose.sh

# Or using the fish alias (after sourcing alias.fish)
sync-goose
```

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

- The `sync-goose.sh` script excludes sensitive files like `history.txt` and temporary backup files
- Configuration changes should be made in the live `~/.config/goose/` directory
- Remember to run `sync-goose` and commit changes to keep your dotfiles repository updated
