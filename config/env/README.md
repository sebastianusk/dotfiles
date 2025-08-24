# Environment Configuration

This directory contains the centralized environment configuration system.

## Files

- **`base.yaml`** - Public environment variables and tool configurations
- **`secret.yaml`** - Secret environment variables (git-ignored)
- **`secret.yaml.example`** - Template for secret configuration
- **`sync-all.sh`** - Master sync script for all tools

## Quick Start

### Initial Setup
```bash
# 1. Create your secret configuration
cp secret.yaml.example secret.yaml
vim secret.yaml  # Add your actual secret values

# 2. Sync to all tools
./sync-all.sh
```

### Daily Usage
```bash
# Edit environment variables
vim base.yaml

# Edit secrets
vim secret.yaml

# Sync changes to all tools
./sync-all.sh
```

## Configuration Sections

### Base Configuration (`base.yaml`)
- **`environment`** - Basic environment variables (EDITOR, PAGER, etc.)
- **`tools`** - Tool-specific configurations (FZF, etc.)
- **`directories`** - Project directory paths
- **`path`** - PATH entries in priority order
- **`fish`** - Fish shell-specific settings

### Secret Configuration (`secret.yaml`)
- **`api_keys`** - API keys and tokens
- **`databases`** - Database connection strings
- **`services`** - Service credentials
- **`other`** - Other secret values

## Adding New Variables

### Add Public Environment Variable
1. Edit `base.yaml`
2. Add to appropriate section
3. Run `./sync-all.sh`

### Add Secret Variable
1. Edit `secret.yaml`
2. Add to appropriate section
3. Run `./sync-all.sh`

### Add PATH Entry
1. Edit `base.yaml`
2. Add to `path` array (order matters - first = highest priority)
3. Run `./sync-all.sh`

## Supported Tools

- **Fish Shell** - Generates `~/.config/fish/env.fish`
- **Zellij** - Merges with base config to create `config.kdl`

## Adding New Tool Support

1. Create `../newtool/sync-env.sh` script
2. Add call to `sync-all.sh`
3. Update tool's README

## Security

- `secret.yaml` is git-ignored and contains actual secret values
- `secret.yaml.example` is version controlled as a template
- Never commit actual secret values to version control
- Secrets are automatically included in all generated configurations

## Dependencies

- **yq** - YAML processor (`brew install yq`)
- **bash** - For sync scripts
