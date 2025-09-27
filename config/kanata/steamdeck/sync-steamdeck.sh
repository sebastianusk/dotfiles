#!/bin/bash

# Kanata configuration sync script
# This script creates symlinks for Kanata configuration files

echo "🚀 Syncing Kanata configuration..."

# Get script directory for relative paths
SCRIPT_DIR="$(dirname "$0")"

# Create kanata config directory if it doesn't exist
echo "📁 Creating Kanata config directory..."
mkdir -p ~/.config/kanata

# Create symlink for Kanata configuration
echo "🔗 Creating kanata.kbd symlink..."
ln -sfn ~/dotfiles/config/kanata/kanata.kbd ~/.config/kanata/kanata.kbd

# Restart systemd service if it's running
if systemctl --user is-active --quiet kanata; then
    echo "🔄 Restarting kanata service..."
    systemctl --user restart kanata
    echo "✅ Service restarted successfully"
elif systemctl --user is-enabled --quiet kanata; then
    echo "🔄 Starting kanata service..."
    systemctl --user start kanata
    echo "✅ Service started successfully"
else
    echo "ℹ️  Kanata service not enabled. Run 'systemctl --user enable kanata' to enable."
fi

echo ""
echo "✅ Kanata configuration sync complete!"
echo ""
echo "📝 Summary:"
echo "   • Created symlink for kanata.kbd"
echo "   • Managed systemd service"
echo ""
echo "🔄 Kanata configuration is now active"
