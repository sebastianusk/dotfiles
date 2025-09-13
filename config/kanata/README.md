# Kanata Keyboard Remapper Setup

## Architecture

- **Home Manager**: Installs the kanata binary only
- **Platform setup scripts**: Handle system permissions and service installation
- **Sync script**: Manages configuration symlinks and service lifecycle

## Setup Instructions

### 1. Install Kanata Binary

Home Manager installs the kanata binary. Apply changes:

```bash
# From nix/steamdeck/ directory
home-manager switch
```

### 2. Platform Setup (Run Once)

#### Linux/SteamOS
```bash
# Handles system permissions, groups, and service installation
./setup-linux.sh
```

#### macOS (Future)
```bash
# Will handle launchd service setup
./setup-mac.sh
```

**Note**: You may need sudo privileges. Log out and log back in after running for group changes to take effect.

### 3. Configuration Management

```bash
# Sync configuration and manage service
./sync.sh
```

The sync script:
- Creates symlinks for kanata.kbd in ~/.config/kanata/
- Manages systemd service (restart if running, start if enabled)

### 4. Service Management

```bash
# Enable service to start on login
systemctl --user enable kanata

# Manual service control
systemctl --user start kanata
systemctl --user stop kanata
systemctl --user status kanata

# View service logs
journalctl --user -u kanata -f
```

## Troubleshooting

### Service Won't Start

1. Check if user is in required groups:
   ```bash
   groups $USER
   # Should include: input uinput
   ```

2. Verify uinput device exists:
   ```bash
   ls -la /dev/uinput
   # Should show: crw-rw---- 1 root uinput
   ```

3. Check keyboard devices:
   ```bash
   ls /dev/input/by-path/ | grep kbd
   ```

4. View detailed logs:
   ```bash
   journalctl --user -u kanata --no-pager
   ```

### SteamOS Updates

After SteamOS updates, you may need to re-run `./setup.sh` as the system files could be reset.
