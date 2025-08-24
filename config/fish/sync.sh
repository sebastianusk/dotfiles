#!/bin/bash

# Fish configuration sync script
# This script creates symlinks for Fish shell configuration files,
# generates environment variables from YAML configuration,
# and installs Fisher plugins

echo "🐟 Syncing Fish configuration..."

# Get script directory for relative paths
SCRIPT_DIR="$(dirname "$0")"
YAML_CONFIG="$SCRIPT_DIR/../env/base.yaml"
SECRET_CONFIG="$SCRIPT_DIR/../env/secret.yaml"
FISH_ENV="$HOME/.config/fish/env.fish"

# Complete cleanup - delete entire Fish config directory
echo "🧹 Completely removing existing Fish configuration..."
rm -rf ~/.config/fish

# Create fresh Fish config directory
echo "📁 Creating fresh Fish config directory..."
mkdir -p ~/.config/fish

# Create symlinks for Fish configuration files
echo "🔗 Creating symlinks..."
ln -sfn ~/dotfiles/config/fish/config.fish ~/.config/fish/config.fish
ln -sfn ~/dotfiles/config/fish/fish_plugins ~/.config/fish/fish_plugins
ln -sfn ~/dotfiles/config/fish/alias.fish ~/.config/fish/alias.fish
ln -sfn ~/dotfiles/config/fish/funct.fish ~/.config/fish/funct.fish

# Generate environment configuration from YAML
echo "📟 Generating fish environment from YAML..."

# Check if yq is available for YAML parsing
if ! command -v yq &> /dev/null; then
    echo "⚠️  yq is required for YAML parsing. Install with: brew install yq"
    echo "   Skipping environment generation..."
else
    if [ ! -f "$YAML_CONFIG" ]; then
        echo "⚠️  YAML config not found at $YAML_CONFIG"
        echo "   Skipping environment generation..."
    else
        cat > "$FISH_ENV" << 'EOF'
# Base environment variables - fish-compatible version
# Generated from base.yaml and secret.yaml - DO NOT EDIT MANUALLY

EOF

        # Parse environment variables
        yq eval '.environment | to_entries | .[] | "set -gx " + .key + " \"" + .value + "\""' "$YAML_CONFIG" >> "$FISH_ENV"

        # Parse directories
        yq eval '.directories | to_entries | .[] | "set -gx " + .key + " \"" + .value + "\""' "$YAML_CONFIG" >> "$FISH_ENV"

        # Parse tools configuration
        TOOLS_EXIST=$(yq eval '.tools | length' "$YAML_CONFIG" 2>/dev/null || echo "0")
        if [ "$TOOLS_EXIST" -gt 0 ]; then
            echo "" >> "$FISH_ENV"
            echo "# Tool configurations" >> "$FISH_ENV"
            
            # Handle each tool variable individually to preserve multiline strings
            for key in $(yq eval '.tools | keys | .[]' "$YAML_CONFIG"); do
                value=$(yq eval ".tools.$key" "$YAML_CONFIG")
                # Escape quotes and handle multiline
                escaped_value=$(echo "$value" | sed 's/"/\\"/g' | tr '\n' ' ')
                echo "set -gx $key \"$escaped_value\"" >> "$FISH_ENV"
            done
        fi

        # Parse secret configuration if it exists
        if [ -f "$SECRET_CONFIG" ]; then
            echo "" >> "$FISH_ENV"
            echo "# Secret environment variables" >> "$FISH_ENV"
            
            # Parse all secret sections
            for section in $(yq eval 'keys | .[]' "$SECRET_CONFIG" 2>/dev/null || echo ""); do
                SECTION_EXIST=$(yq eval ".$section | length" "$SECRET_CONFIG" 2>/dev/null || echo "0")
                if [ "$SECTION_EXIST" -gt 0 ]; then
                    echo "# $section" >> "$FISH_ENV"
                    yq eval ".$section | to_entries | .[] | \"set -gx \" + .key + \" \\\"\" + .value + \"\\\"\"" "$SECRET_CONFIG" >> "$FISH_ENV"
                fi
            done
        else
            echo "" >> "$FISH_ENV"
            echo "# No secret configuration found at $SECRET_CONFIG" >> "$FISH_ENV"
        fi

        # Add GPG_TTY (dynamic variable with safety check)
        echo "" >> "$FISH_ENV"
        echo "# Dynamic variables" >> "$FISH_ENV"
        echo "if command -v tty >/dev/null 2>&1" >> "$FISH_ENV"
        echo "    set -gx GPG_TTY (tty)" >> "$FISH_ENV"
        echo "end" >> "$FISH_ENV"

        # Add PATH configuration
        echo "" >> "$FISH_ENV"
        echo "# PATH configuration using fish_add_path (fish-specific optimization)" >> "$FISH_ENV"
        echo "fish_add_path -p \\" >> "$FISH_ENV"

        # Parse PATH entries
        PATH_ENTRIES=$(yq eval '.path[]' "$YAML_CONFIG")
        PATH_COUNT=$(echo "$PATH_ENTRIES" | wc -l)
        CURRENT=1

        while IFS= read -r path_entry; do
            if [ $CURRENT -eq $PATH_COUNT ]; then
                echo "    \"$path_entry\"" >> "$FISH_ENV"
            else
                echo "    \"$path_entry\" \\" >> "$FISH_ENV"
            fi
            ((CURRENT++))
        done <<< "$PATH_ENTRIES"

        echo "✅ Fish environment generated at $FISH_ENV"
        if [ -f "$SECRET_CONFIG" ]; then
            echo "🔐 Secrets included from $SECRET_CONFIG"
        else
            echo "⚠️  No secrets file found - create $SECRET_CONFIG from secret.yaml.example"
        fi
    fi
fi

# Install Fisher and plugins
echo "🎣 Installing Fisher and plugins..."
if command -v fish >/dev/null 2>&1; then
    # Install Fisher if not already installed
    fish -c "
        if not functions -q fisher
            echo '📦 Installing Fisher...'
            curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source
            fisher install jorgebucaran/fisher
        else
            echo '✅ Fisher already installed'
        end
    "
    
    # Install plugins from fish_plugins file
    if [ -f ~/.config/fish/fish_plugins ]; then
        echo "📋 Installing plugins from fish_plugins..."
        fish -c "fisher update"
        
        # List installed plugins for confirmation
        echo "🔌 Installed plugins:"
        fish -c "fisher list" 2>/dev/null || echo "   (Fisher list not available)"
    else
        echo "⚠️  No fish_plugins file found, skipping plugin installation"
    fi
else
    echo "⚠️  Fish shell not found, skipping Fisher installation"
fi

echo ""
echo "✅ Fish configuration sync complete!"
echo ""
echo "📝 Summary:"
echo "   • Completely removed old ~/.config/fish directory"
echo "   • Created fresh directory with symlinks"
echo "   • Generated environment variables from YAML"
echo "   • FZF configuration is now directly in config.fish"
echo "   • Installed Fisher and all plugins from fish_plugins"
echo ""
echo "🔄 To apply changes, restart your terminal or run: exec fish"
