# Kanata Setup for macOS

## Overview

This guide will help you install and configure Kanata on macOS to implement the unified keyboard shortcut scheme defined in `shortcut.md`.

**IMPORTANT**: Kanata on macOS requires the Karabiner Virtual HID Driver to function properly.

## Installation Steps

### 1. Install Karabiner Virtual HID Driver (REQUIRED - Manual Installation)

**This is mandatory - Kanata will not work without it!**

**Manual Installation Steps:**
1. Go to [Karabiner-DriverKit-VirtualHIDDevice releases](https://github.com/pqrs-org/Karabiner-DriverKit-VirtualHIDDevice/tree/main/dist)
2. Download the latest .pkg file (currently v6.2.0 or newer)
3. Double-click the .pkg file and follow installation instructions
4. **Critical**: Use System Settings to grant the driver privileges when prompted
5. Reboot your Mac after installation

**Alternative CLI Installation:**
```bash
# Download latest driver
curl -L -o karabiner-driver.pkg "https://github.com/pqrs-org/Karabiner-DriverKit-VirtualHIDDevice/raw/main/dist/Karabiner-DriverKit-VirtualHIDDevice-6.2.0.pkg"

# Install via CLI
sudo installer -pkg karabiner-driver.pkg -target /
```

**Verify Installation:**
```bash
ls -la "/Library/Application Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice"
```

### 2. Install Kanata

```bash
brew install kanata
```

### 3. Run Setup Script

```bash
cd /Users/admin/dotfiles/config/kanata/mac
./setup-mac.sh
```

This script will:
- Check for required Karabiner driver
- Create system launch daemons
- Set up configuration symlinks
- Provide next steps

### 4. Grant Required Permissions (CRITICAL)

**Input Monitoring** (Required):
1. Open **System Settings** → **Privacy & Security** → **Input Monitoring**
2. Click the lock icon and enter your password
3. Click **+** and navigate to `/opt/homebrew/bin/kanata` (use Cmd+Shift+G)
4. Select the kanata binary and enable the checkbox

**Accessibility** (Required):
1. Open **System Settings** → **Privacy & Security** → **Accessibility**
2. Click **+** and add the same `/opt/homebrew/bin/kanata` binary
3. Enable the checkbox for Kanata

### 5. Test Manual Operation

```bash
sudo kanata --cfg ~/.config/kanata/kanata.kbd
```

**Expected output:**
```
[INFO] kanata v1.9.0 starting
[INFO] process unmapped keys: true
[INFO] config file is valid
[INFO] Sleeping for 2s. Please release all keys...
[INFO] entering the processing loop
[INFO] entering the event loop
[INFO] Starting kanata proper
```

**If you see "IOHIDDeviceOpen error: not permitted"** - you need to grant Input Monitoring permissions (step 4).

Press `Ctrl+C` to exit the test.

### 6. Load and Enable Services

```bash
# Load the services
sudo launchctl bootstrap system /Library/LaunchDaemons/com.kanata.karabiner-vhiddaemon.plist
sudo launchctl bootstrap system /Library/LaunchDaemons/com.kanata.plist

# Enable services to start on boot
sudo launchctl enable system/com.kanata.karabiner-vhiddaemon
sudo launchctl enable system/com.kanata
```

## Validation Checklist

Run these commands to verify everything is working:

```bash
# 1. Check Kanata installation
which kanata && kanata --version

# 2. Check configuration
ls -la ~/.config/kanata/kanata.kbd

# 3. Check services are loaded
sudo launchctl list | grep kanata

# 4. Test configuration syntax
kanata --cfg ~/.config/kanata/kanata.kbd --check

# 5. Check if driver is installed
ls -la "/Library/Application Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice"
```

## Service Management

### Check Service Status
```bash
sudo launchctl list | grep kanata
```

### Manual Control
```bash
# Start services
sudo launchctl start com.kanata.karabiner-vhiddaemon
sudo launchctl start com.kanata

# Stop services
sudo launchctl stop com.kanata
sudo launchctl stop com.kanata.karabiner-vhiddaemon

# Restart services
sudo launchctl stop com.kanata && sudo launchctl start com.kanata
```

### View Logs
```bash
# View recent logs
sudo tail -f /Library/Logs/Kanata/kanata.out.log
sudo tail -f /Library/Logs/Kanata/kanata.err.log
```

## Testing Your Setup

### Current Configuration
Your basic setup includes homerow modifiers:
- **Caps Lock (hold)** → Cmd+Opt, **tap** → Escape
- **S/L (hold)** → Alt, **tap** → S/L
- **D/K (hold)** → Ctrl, **tap** → D/K
- **F/J (hold)** → Shift, **tap** → F/J

### Test Basic Functionality
1. Hold **Caps Lock + Space** → Should trigger Spotlight (Cmd+Opt+Space)
2. Hold **D + C** → Should copy (Ctrl+C)
3. Tap **Caps Lock** → Should send Escape

## Troubleshooting

### Common Issues

**"IOHIDDeviceOpen error: (iokit/common) not permitted"**
- Grant Input Monitoring permissions to `/opt/homebrew/bin/kanata`
- Grant Accessibility permissions to `/opt/homebrew/bin/kanata`

**"Couldn't register any device"**
- Install Karabiner-DriverKit-VirtualHIDDevice
- Ensure the VHIDDaemon service is running
- Only one instance of Kanata can run at a time

**Service won't start**
```bash
# Check service status
sudo launchctl list | grep kanata

# Check logs for errors
sudo tail -20 /Library/Logs/Kanata/kanata.err.log

# Verify plist syntax
plutil /Library/LaunchDaemons/com.kanata.plist
```

**Permission denied errors**
- Ensure plist files are owned by root:wheel
- Use `sudo chown root:wheel /Library/LaunchDaemons/com.kanata*.plist`

### Important Notes

- **Version compatibility**: Use latest Karabiner-DriverKit-VirtualHIDDevice (v6.2.0+)
- **Conflicts**: Cannot run alongside Karabiner-Elements
- **Permissions**: Both Input Monitoring AND Accessibility are required
- **Single instance**: Only one Kanata process can run at a time
- **System daemons**: Kanata runs as system daemon, not user agent

## Next Steps

After successful installation, you'll configure the keyboard mappings step by step based on `shortcut.md`:

1. **Part 1**: Universal Copy & Paste (Super+C/V)
2. **Part 2**: Universal Application Shortcuts (Ctrl+Key → Cmd+Key)
3. **Part 3**: Navigation Layer (A+hjkl)
4. **Part 4**: Desktop Commands (Caps+Key)
5. **Part 5**: Window Management (Amethyst integration)

Each part will be implemented incrementally in the `kanata.kbd` configuration file.
