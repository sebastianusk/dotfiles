#!/bin/bash
# Sync environment from YAML to zellij config
# Run this script from the zellij config directory

SCRIPT_DIR="$(dirname "$0")"
YAML_CONFIG="$SCRIPT_DIR/../env/base.yaml"
SECRET_CONFIG="$SCRIPT_DIR/../env/secret.yaml"
ZELLIJ_BASE="$SCRIPT_DIR/zellij.kdl"
ZELLIJ_CONFIG="$SCRIPT_DIR/config.kdl"

# Check if yq is available for YAML parsing
if ! command -v yq &> /dev/null; then
    echo "❌ yq is required for YAML parsing. Install with: brew install yq"
    exit 1
fi

if [ ! -f "$YAML_CONFIG" ]; then
    echo "❌ YAML config not found at $YAML_CONFIG"
    exit 1
fi

if [ ! -f "$ZELLIJ_BASE" ]; then
    echo "❌ Zellij base config not found at $ZELLIJ_BASE"
    exit 1
fi

echo "🖥️  Generating zellij configuration..."

# Create temporary environment block
TEMP_ENV=$(mktemp)
cat > "$TEMP_ENV" << 'EOF'
env {
EOF

# Build PATH from YAML
PATH_VALUE=""
while IFS= read -r path_entry; do
    if [ -z "$PATH_VALUE" ]; then
        PATH_VALUE="$path_entry"
    else
        PATH_VALUE="$PATH_VALUE:$path_entry"
    fi
done <<< "$(yq eval '.path[]' "$YAML_CONFIG")"

# Add original PATH
PATH_VALUE="$PATH_VALUE:\$PATH"

echo "    PATH \"$PATH_VALUE\"" >> "$TEMP_ENV"

# Add environment variables
yq eval '.environment | to_entries | .[] | "    " + .key + " \"" + .value + "\""' "$YAML_CONFIG" >> "$TEMP_ENV"

# Add directories
yq eval '.directories | to_entries | .[] | "    " + .key + " \"" + .value + "\""' "$YAML_CONFIG" >> "$TEMP_ENV"

# Add tools configuration
TOOLS_EXIST=$(yq eval '.tools | length' "$YAML_CONFIG" 2>/dev/null || echo "0")
if [ "$TOOLS_EXIST" -gt 0 ]; then
    for key in $(yq eval '.tools | keys | .[]' "$YAML_CONFIG"); do
        value=$(yq eval ".tools.$key" "$YAML_CONFIG")
        # Escape quotes and handle multiline for zellij
        escaped_value=$(echo "$value" | sed 's/"/\\"/g' | tr '\n' ' ')
        echo "    $key \"$escaped_value\"" >> "$TEMP_ENV"
    done
fi

# Add secret configuration if it exists
if [ -f "$SECRET_CONFIG" ]; then
    # Parse all secret sections
    for section in $(yq eval 'keys | .[]' "$SECRET_CONFIG" 2>/dev/null || echo ""); do
        SECTION_EXIST=$(yq eval ".$section | length" "$SECRET_CONFIG" 2>/dev/null || echo "0")
        if [ "$SECTION_EXIST" -gt 0 ]; then
            yq eval ".$section | to_entries | .[] | \"    \" + .key + \" \\\"\" + .value + \"\\\"\"" "$SECRET_CONFIG" >> "$TEMP_ENV"
        fi
    done
fi

echo "}" >> "$TEMP_ENV"

# Combine environment block with base zellij config
{
    cat "$TEMP_ENV"
    echo ""
    cat "$ZELLIJ_BASE"
} > "$ZELLIJ_CONFIG"

# Clean up
rm "$TEMP_ENV"

echo "✅ Zellij config generated at $ZELLIJ_CONFIG"
if [ -f "$SECRET_CONFIG" ]; then
    echo "🔐 Secrets included from $SECRET_CONFIG"
else
    echo "⚠️  No secrets file found - create $SECRET_CONFIG from secret.yaml.example"
fi
echo ""
echo "Configuration merged from:"
echo "  • Environment: $YAML_CONFIG"
echo "  • Base config: $ZELLIJ_BASE"
if [ -f "$SECRET_CONFIG" ]; then
    echo "  • Secrets: $SECRET_CONFIG"
fi
echo ""
echo "Next steps:"
echo "  • Restart zellij or start new session to pick up changes"
