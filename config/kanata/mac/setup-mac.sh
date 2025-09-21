#!/bin/bash
# Kanata setup script for macOS
# Run this script once to set up directories and services for kanata

set -e

echo "Setting up kanata for macOS..."

# Check if Karabiner Virtual HID Driver is installed
if [ ! -d "/Library/Application Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice" ]; then
    echo ""
    echo "❌ CRITICAL: Karabiner-DriverKit-VirtualHIDDevice is required but not found!"
    echo ""
    echo "Please install it manually first:"
    echo "1. Go to: https://github.com/pqrs-org/Karabiner-DriverKit-VirtualHIDDevice/tree/main/dist"
    echo "2. Download the latest .pkg file (v6.2.0 or newer)"
    echo "3. Double-click the .pkg file to install"
    echo "4. Follow system prompts to grant driver privileges"
    echo "5. Rerun this script after installation"
    echo ""
    exit 1
fi

# Create config directory
echo "Creating config directory..."
mkdir -p ~/.config/kanata

# Create system launch daemon (requires sudo)
echo "Creating system launch daemon..."
sudo mkdir -p /Library/Logs/Kanata

# Create Karabiner VHIDDaemon service
sudo tee /Library/LaunchDaemons/com.kanata.karabiner-vhiddaemon.plist > /dev/null << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.kanata.karabiner-vhiddaemon</string>
    <key>ProgramArguments</key>
    <array>
        <string>/Library/Application Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice/Applications/Karabiner-VirtualHIDDevice-Daemon.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Daemon</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
</dict>
</plist>
EOF

# Create Kanata service
KANATA_PATH=$(which kanata)
sudo tee /Library/LaunchDaemons/com.kanata.plist > /dev/null << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.kanata</string>
    <key>ProgramArguments</key>
    <array>
        <string>$KANATA_PATH</string>
        <string>--cfg</string>
        <string>/Users/admin/.config/kanata/kanata.kbd</string>
        <string>--port</string>
        <string>10000</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/Library/Logs/Kanata/kanata.out.log</string>
    <key>StandardErrorPath</key>
    <string>/Library/Logs/Kanata/kanata.err.log</string>
</dict>
</plist>
EOF

echo "Running sync script to configure kanata..."
"$(dirname "$0")/sync-mac.sh"

echo ""
echo "Setup complete!"
echo ""
echo "CRITICAL NEXT STEPS:"
echo "1. Grant Input Monitoring permissions:"
echo "   System Settings → Privacy & Security → Input Monitoring"
echo "   Click '+' and add: $KANATA_PATH"
echo ""
echo "2. Grant Accessibility permissions:"
echo "   System Settings → Privacy & Security → Accessibility"
echo "   Click '+' and add: $KANATA_PATH"
echo ""
echo "3. Load services:"
echo "   sudo launchctl bootstrap system /Library/LaunchDaemons/com.kanata.karabiner-vhiddaemon.plist"
echo "   sudo launchctl bootstrap system /Library/LaunchDaemons/com.kanata.plist"
echo ""
echo "4. Enable services:"
echo "   sudo launchctl enable system/com.kanata.karabiner-vhiddaemon"
echo "   sudo launchctl enable system/com.kanata"
echo ""
echo "To test manually (after permissions):"
echo "  sudo kanata --cfg ~/.config/kanata/kanata.kbd"
