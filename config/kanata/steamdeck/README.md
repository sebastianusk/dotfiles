# Kanata Setup for Steam Deck/SteamOS

## Overview

This guide will help you install and configure Kanata on Steam Deck/SteamOS to implement the unified keyboard shortcut scheme defined in the main kanata configuration.

**IMPORTANT**: Kanata on Steam Deck requires proper uinput permissions and group membership to function correctly.

## Installation Steps

### 1. Install Kanata Binary

Install Kanata through your package manager or Home Manager:

**Via Nix/Home Manager:**
```bash
# From your nix configuration directory
home-manager switch
```

**Via Package Manager (if available):**
```bash
# Check if kanata is available in your package manager
sudo pacman -S kanata  # Arch-based (SteamOS)
```

### 2. Run Setup Script

```bash
cd ~/dotfiles/config/kanata/steamdeck
./setup-steamdeck.sh
```

This script will:
- Add your user to required groups (input, uinput)
- Create udev rules for device access
- Load and configure uinput kernel module
- Install systemd user service
- Install OpenRC service (if detected)
- Run the sync script to configure kanata

**IMPORTANT**: You will need sudo privileges and must log out/log in after running for group changes to take effect.

### 3. Grant Required Permissions

Unlike macOS, Steam Deck/SteamOS primarily uses group-based permissions:

**User Groups** (Required):
```bash
# Verify you're in the correct groups
groups $USER
# Should include: input uinput
```

**Device Access** (Automatically configured):
```bash
# Verify uinput device exists and has correct permissions
ls -la /dev/uinput
# Should show: crw-rw---- 1 root uinput
```

### 4. Test Manual Operation

```bash
# Test kanata configuration
kanata --cfg ~/.config/kanata/kanata.kbd --check

# Test manual run (requires groups setup)
kanata --cfg ~/.config/kanata/kanata.kbd
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

Press `Ctrl+C` to exit the test.

### 5. Enable and Start Services

```bash
# Enable service to start on login
systemctl --user enable kanata

# Start the service
systemctl --user start kanata
```

## Service Management

### Check Service Status
```bash
systemctl --user status kanata
```

### Manual Control
```bash
# Start service
systemctl --user start kanata

# Stop service
systemctl --user stop kanata

# Restart service
systemctl --user restart kanata

# Enable on login
systemctl --user enable kanata

# Disable
systemctl --user disable kanata
```

### View Logs
```bash
# View recent logs
journalctl --user -u kanata -f

# View all logs
journalctl --user -u kanata --no-pager
```

## Configuration Management

### Sync Configuration
```bash
# Update configuration and restart service
./sync-steamdeck.sh
```

The sync script:
- Creates symlinks for kanata.kbd in ~/.config/kanata/
- Manages systemd service (restart if running, start if enabled)

## Testing Your Setup

### Current Configuration
Your setup includes homerow modifiers and function key improvements:

**Homerow Modifiers:**
- **Caps Lock (hold)** → Cmd+Opt, **tap** → Escape
- **A/; (hold)** → Shift, **tap** → A/;
- **S/L (hold)** → Alt, **tap** → S/L  
- **D/K (hold)** → Super/Cmd, **tap** → D/K
- **F/J (hold)** → Ctrl, **tap** → F/J

**Function Keys:**
- **Default:** F1=brightness down, F2=brightness up, F7-F12=media controls
- **With Fn held:** F1=actual F1, F2=actual F2, etc.

**Navigation Layer:**
- **Space (hold) + hjkl** → Arrow keys

## Troubleshooting

### Common Issues

**"Permission denied" or "Operation not permitted"**
- Ensure you're in the input and uinput groups: `groups $USER`
- Log out and log back in after running setup script
- Verify udev rules: `ls -la /etc/udev/rules.d/*input*`

**"No such file or directory: /dev/uinput"**
- Load uinput module: `sudo modprobe uinput`
- Check if module loads on boot: `cat /etc/modules-load.d/uinput.conf`

**Service won't start**
```bash
# Check service status and logs
systemctl --user status kanata
journalctl --user -u kanata --no-pager

# Verify service file
cat ~/.config/systemd/user/kanata.service

# Reload daemon if service file changed
systemctl --user daemon-reload
```

### Steam Deck Specific Issues

**After SteamOS Updates:**
- System may reset permissions and services
- Re-run `./setup-steamdeck.sh` after major updates
- Check that user groups are still correct

**Desktop Mode vs Gaming Mode:**
- Kanata works in Desktop Mode
- Gaming Mode may have different permission requirements
- Switch to Desktop Mode for initial setup and testing

## File Structure

```
steamdeck/
├── README.md              # This file
├── setup-steamdeck.sh     # One-time setup script
├── sync-steamdeck.sh      # Configuration sync script  
├── kanata.service         # Systemd user service
└── kanata.openrc          # OpenRC service (alternative)
```