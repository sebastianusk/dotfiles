#!/bin/bash
# Sync kanata configuration and manage service on macOS

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KANATA_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG_DIR="$HOME/.config/kanata"

echo "Syncing kanata configuration..."

# Create config directory if it doesn't exist
mkdir -p "$CONFIG_DIR"

# Remove existing symlink/file and create new symlink
rm -f "$CONFIG_DIR/kanata.kbd"
ln -sf "$KANATA_DIR/kanata.kbd" "$CONFIG_DIR/kanata.kbd"

echo "Configuration synced: $CONFIG_DIR/kanata.kbd -> $KANATA_DIR/kanata.kbd"

# Check if system services are loaded and restart if needed
if sudo launchctl list | grep -q "com.kanata"; then
    echo "Restarting kanata services..."
    sudo launchctl stop com.kanata 2>/dev/null || true
    sudo launchctl stop com.kanata.karabiner-vhiddaemon 2>/dev/null || true
    sleep 2
    sudo launchctl start com.kanata.karabiner-vhiddaemon 2>/dev/null || true
    sleep 1
    sudo launchctl start com.kanata 2>/dev/null || true
    echo "Services restarted"
else
    echo "Services not loaded. To start kanata:"
    echo "  sudo launchctl bootstrap system /Library/LaunchDaemons/com.kanata.karabiner-vhiddaemon.plist"
    echo "  sudo launchctl bootstrap system /Library/LaunchDaemons/com.kanata.plist"
    echo "  sudo launchctl enable system/com.kanata.karabiner-vhiddaemon"
    echo "  sudo launchctl enable system/com.kanata"
fi

echo "Sync complete!"
