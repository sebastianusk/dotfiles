# Fish Shell Configuration

This directory contains Fish shell configuration files.

## Files

### Version Controlled Files
- **`config.fish`** - Main Fish configuration file
- **`alias.fish`** - Shell aliases
- **`funct.fish`** - Custom Fish functions
- **`sync-env.sh`** - Environment synchronization script

### Generated Files (Git Ignored)
- **`env.fish`** - Generated environment variables from YAML

## Quick Usage

### Update Environment Variables
```bash
# 1. Edit the YAML source
vim ../env/base.yaml

# 2. Sync environment to Fish
./sync-env.sh

# 3. Reload Fish configuration
source ~/.config/fish/config.fish
```

### Update Secrets
```bash
# 1. Edit secrets
vim ../env/secret.yaml

# 2. Sync to Fish
./sync-env.sh

# 3. Reload Fish
source ~/.config/fish/config.fish
```

### Sync All Tools at Once
```bash
cd ../env && ./sync-all.sh
```

## Environment Management

Environment variables are managed centrally in `../env/base.yaml` and `../env/secret.yaml`, then generated into `env.fish`.

### What Goes Where
- **Public variables** → `../env/base.yaml`
- **Secret variables** → `../env/secret.yaml`
- **Fish-specific settings** → `../env/base.yaml` (fish section)
- **Fish shell behavior** → `config.fish`, `alias.fish`, `funct.fish`

## Important Notes

- **DO NOT** edit `env.fish` directly - it will be overwritten
- **DO NOT** commit `env.fish` - it's generated from YAML
- Environment variables should be added to the YAML files
- Fish-specific configurations go in the `fish` section of `base.yaml`

## Adding New Configurations

### Add Environment Variable
1. Edit `../env/base.yaml`
2. Add to appropriate section (environment, tools, directories, path)
3. Run `./sync-env.sh`

### Add Secret
1. Edit `../env/secret.yaml`
2. Add to appropriate section
3. Run `./sync-env.sh`

### Add Fish-Specific Setting
1. Edit `../env/base.yaml`
2. Add to `fish` section
3. Run `./sync-env.sh`

### Add Alias or Function
1. Edit `alias.fish` or `funct.fish` directly
2. Reload: `source ~/.config/fish/config.fish`
