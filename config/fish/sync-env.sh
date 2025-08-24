#!/bin/bash
# Sync environment from YAML to fish config
# Run this script from the fish config directory

SCRIPT_DIR="$(dirname "$0")"
YAML_CONFIG="$SCRIPT_DIR/../env/base.yaml"
SECRET_CONFIG="$SCRIPT_DIR/../env/secret.yaml"
FISH_ENV="$HOME/.config/fish/env.fish"

# Check if yq is available for YAML parsing
if ! command -v yq &> /dev/null; then
    echo "❌ yq is required for YAML parsing. Install with: brew install yq"
    exit 1
fi

if [ ! -f "$YAML_CONFIG" ]; then
    echo "❌ YAML config not found at $YAML_CONFIG"
    exit 1
fi

echo "📟 Generating fish environment..."
mkdir -p "$(dirname "$FISH_ENV")"

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

# Add GPG_TTY (dynamic variable)
echo "" >> "$FISH_ENV"
echo "# Dynamic variables" >> "$FISH_ENV"
echo "set -gx GPG_TTY (tty)" >> "$FISH_ENV"

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

# Add fish-specific configurations
FISH_EXIST=$(yq eval '.fish | length' "$YAML_CONFIG" 2>/dev/null || echo "0")
if [ "$FISH_EXIST" -gt 0 ]; then
    echo "" >> "$FISH_ENV"
    echo "# Fish-specific configurations" >> "$FISH_ENV"
    
    # FZF bindings
    FZF_BINDINGS_EXIST=$(yq eval '.fish.fzf_bindings | length' "$YAML_CONFIG" 2>/dev/null || echo "0")
    if [ "$FZF_BINDINGS_EXIST" -gt 0 ]; then
        DIRECTORY_BINDING=$(yq eval '.fish.fzf_bindings.directory' "$YAML_CONFIG")
        echo "fzf_configure_bindings --directory=$DIRECTORY_BINDING" >> "$FISH_ENV"
    fi
fi

echo "✅ Fish environment generated at $FISH_ENV"
if [ -f "$SECRET_CONFIG" ]; then
    echo "🔐 Secrets included from $SECRET_CONFIG"
else
    echo "⚠️  No secrets file found - create $SECRET_CONFIG from secret.yaml.example"
fi
echo ""
echo "Configuration source: $YAML_CONFIG"
echo ""
echo "Next steps:"
echo "  • Restart fish shell or run: source ~/.config/fish/config.fish"
