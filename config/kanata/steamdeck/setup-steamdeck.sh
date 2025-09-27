#!/bin/sh
# Kanata setup script for Steam Deck/SteamOS
# Run this script once to set up system permissions and services for kanata

set -e

echo "Setting up kanata permissions and services for Steam Deck/SteamOS..."

# Create uinput group first
echo "Creating uinput group..."
sudo groupadd uinput 2>/dev/null || echo "uinput group already exists"

# Add current user to required groups
echo "Adding user to input and uinput groups..."
sudo usermod -aG input "$USER"
sudo usermod -aG uinput "$USER"

# Create udev rule for uinput device access
echo "Creating udev rule..."
echo 'KERNEL=="uinput", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"' | sudo tee /etc/udev/rules.d/99-input.rules > /dev/null

# Reload udev rules
echo "Reloading udev rules..."
sudo udevadm control --reload-rules
sudo udevadm trigger

# Load uinput kernel module
echo "Loading uinput kernel module..."
sudo modprobe uinput

# Make uinput load on boot
echo "Setting uinput to load on boot..."
echo 'uinput' | sudo tee -a /etc/modules-load.d/uinput.conf > /dev/null

# Install systemd user service
echo "Installing systemd user service..."
mkdir -p ~/.config/systemd/user
# Remove existing service file/link if it exists
rm -f ~/.config/systemd/user/kanata.service
cp "$(dirname "$0")/kanata.service" ~/.config/systemd/user/
systemctl --user daemon-reload
echo "To enable the service, run: systemctl --user enable kanata.service"
echo "To start the service, run: systemctl --user start kanata.service"

# Install OpenRC service (if OpenRC is detected)
if command -v rc-update >/dev/null 2>&1; then
    echo "OpenRC detected. Installing OpenRC service..."
    sudo cp "$(dirname "$0")/kanata.openrc" /etc/init.d/kanata
    sudo chmod +x /etc/init.d/kanata
    echo "To enable the service, run: sudo rc-update add kanata default"
    echo "To start the service, run: sudo rc-service kanata start"
fi

echo ""
echo "Running sync script to configure kanata..."
"$(dirname "$0")/sync-steamdeck.sh"

echo ""
echo "Setup complete!"
echo "Please log out and log back in for group changes to take effect."
