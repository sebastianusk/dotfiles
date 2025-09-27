# Kanata Keyboard Remapper Setup

## Directory Structure

```
config/kanata/
├── kanata.kbd                 # Main configuration file
├── README.md                  # This file
├── mac/                       # macOS-specific setup
│   ├── README.md              # Detailed macOS setup guide
│   ├── setup-mac.sh           # macOS setup script
│   └── sync-mac.sh            # macOS sync script
└── steamdeck/                 # Steam Deck/Linux setup
    ├── README.md              # Detailed Steam Deck setup guide
    ├── setup-steamdeck.sh     # Steam Deck setup script
    ├── sync-steamdeck.sh      # Steam Deck sync script
    ├── kanata.service         # Systemd user service
    └── kanata.openrc          # OpenRC service
```

## Quick Start

### 1. Choose Your Platform

Navigate to the appropriate platform directory and follow the detailed setup instructions:

#### macOS
```bash
cd config/kanata/mac
cat README.md  # Read the full setup guide
./setup-mac.sh
```

#### Steam Deck / SteamOS / Linux
```bash
cd config/kanata/steamdeck  
cat README.md  # Read the full setup guide
./setup-steamdeck.sh
```

### 2. Configuration Management

Each platform has its own sync script:

```bash
# macOS
./mac/sync-mac.sh

# Steam Deck/Linux  
./steamdeck/sync-steamdeck.sh
```

## Configuration Overview

The main `kanata.kbd` file includes:

**Homerow Modifiers:**
- **Caps Lock**: tap=Escape, hold=Cmd+Opt for desktop commands
- **A/S/D/F and J/K/L/;**: Hold for Shift/Alt/Super/Ctrl modifiers
- **Space**: Hold for navigation layer (hjkl → arrow keys)

**Function Keys:**  
- **Default**: F1/F2=brightness, F7-F12=media controls
- **With Fn**: Regular F1-F12 function keys

**Live Reload:**
- Hold **`** (backtick/grave) to reload configuration

## Platform-Specific Details

Each platform directory contains:
- **README.md**: Comprehensive setup and troubleshooting guide
- **Setup script**: One-time installation and configuration  
- **Sync script**: Configuration updates and service management
- **Service files**: Platform-appropriate service definitions

For detailed installation instructions, troubleshooting, and platform-specific notes, see the README in your platform's directory.
