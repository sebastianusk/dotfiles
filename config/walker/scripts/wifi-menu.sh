#!/usr/bin/env bash
#
# Walker WiFi Menu
# Adapted from rofi-network-manager
#
# A script that generates a walker menu for NetworkManager wifi management
#

# Get the wifi interface
WIFI_INTERFACE=$(nmcli device | awk '$2=="wifi" {print $1; exit}')

if [ -z "$WIFI_INTERFACE" ]; then
    echo "No WiFi interface found" | walker --dmenu
    exit 1
fi

# Check if wifi is enabled
wifi_enabled() {
    if nmcli radio wifi | grep -q "enabled"; then
        return 0
    else
        return 1
    fi
}

# Get current connection status
get_wifi_status() {
    WIFI_STATE=$(nmcli -t -f DEVICE,STATE device status | grep "^${WIFI_INTERFACE}:" | cut -d: -f2)
    ACTIVE_SSID=$(nmcli -t -f GENERAL.CONNECTION dev show "$WIFI_INTERFACE" | cut -d: -f2)

    if [ "$ACTIVE_SSID" = "--" ] || [ -z "$ACTIVE_SSID" ]; then
        ACTIVE_SSID=""
    fi
}

# Toggle wifi on/off
toggle_wifi() {
    if wifi_enabled; then
        nmcli radio wifi off
    else
        nmcli radio wifi on
        sleep 2
    fi
    show_menu
}

# Disconnect from current network
disconnect_wifi() {
    if [ -n "$ACTIVE_SSID" ]; then
        nmcli con down id "$ACTIVE_SSID"
        sleep 1
    fi
    show_menu
}

# Scan for networks
scan_networks() {
    nmcli device wifi rescan ifname "$WIFI_INTERFACE" 2>/dev/null
    sleep 2
    show_menu
}

# Connect to a network
connect_network() {
    SSID="$1"
    SECURITY="$2"

    # Check if this is a known connection
    if nmcli -t -f NAME connection show | grep -q "^${SSID}$"; then
        # Stored connection - just activate it
        if nmcli con up id "$SSID" ifname "$WIFI_INTERFACE" 2>/dev/null; then
            echo "✓ Connected to $SSID" | walker --dmenu
        else
            echo "✗ Failed to connect to $SSID" | walker --dmenu
        fi
    else
        # New connection - need password if secured
        if [ "$SECURITY" != "--" ] && [ -n "$SECURITY" ]; then
            # Prompt for password
            PASS=$(echo "Enter password for $SSID" | walker --dmenu)
            if [ -n "$PASS" ]; then
                if nmcli dev wifi con "$SSID" password "$PASS" ifname "$WIFI_INTERFACE" 2>/dev/null; then
                    echo "✓ Connected to $SSID" | walker --dmenu
                else
                    echo "✗ Failed to connect to $SSID" | walker --dmenu
                fi
            fi
        else
            # Open network - no password needed
            if nmcli dev wifi con "$SSID" ifname "$WIFI_INTERFACE" 2>/dev/null; then
                echo "✓ Connected to $SSID" | walker --dmenu
            else
                echo "✗ Failed to connect to $SSID" | walker --dmenu
            fi
        fi
    fi
}

# Main menu
show_menu() {
    get_wifi_status

    if ! wifi_enabled; then
        # WiFi is disabled
        options="📡 WiFi: OFF (click to enable)"
        chosen=$(echo -e "$options" | walker --dmenu)

        case "$chosen" in
            *"WiFi: OFF"*)
                toggle_wifi
                ;;
        esac
        exit 0
    fi

    # WiFi is enabled - build menu
    if [ -n "$ACTIVE_SSID" ]; then
        status="📡 Connected: $ACTIVE_SSID"
        actions="🔄 Scan\n🔌 Disconnect\n📴 WiFi OFF"
    else
        status="📡 WiFi: ON (not connected)"
        actions="🔄 Scan\n📴 WiFi OFF"
    fi

    # Get list of available networks
    networks=$(nmcli -t -f SSID,SECURITY,SIGNAL,IN-USE device wifi list ifname "$WIFI_INTERFACE" | \
        awk -F: '
        {
            ssid = $1
            security = $2
            signal = $3
            in_use = $4

            if (ssid == "") next

            # Signal strength icon
            if (signal >= 75) icon = "▂▄▆█"
            else if (signal >= 50) icon = "▂▄▆_"
            else if (signal >= 25) icon = "▂▄__"
            else icon = "▂___"

            # Security icon
            if (security == "" || security == "--") sec = "🔓"
            else sec = "🔒"

            # Active indicator
            if (in_use == "*") active = "🔵 "
            else active = "⚪ "

            printf "%s%s %s %s %s\n", active, ssid, icon, sec, security
        }' | head -20)

    # Combine everything
    divider="─────────────────"
    if [ -n "$networks" ]; then
        options="$status\n$divider\n$networks\n$divider\n$actions"
    else
        options="$status\n$divider\n$actions"
    fi

    # Show menu
    chosen=$(echo -e "$options" | walker --dmenu)

    # Handle selection
    case "$chosen" in
        "")
            exit 0
            ;;
        "$status"|"$divider")
            exit 0
            ;;
        "🔄 Scan")
            scan_networks
            ;;
        "🔌 Disconnect")
            disconnect_wifi
            ;;
        *"WiFi OFF")
            toggle_wifi
            ;;
        *)
            # Network selected
            if echo "$chosen" | grep -q "^[🔵⚪]"; then
                # Extract SSID and security from the chosen line
                SSID=$(echo "$chosen" | awk '{print $2}')
                SECURITY=$(echo "$chosen" | awk '{print $NF}')

                if [ "$SECURITY" = "🔓" ] || [ "$SECURITY" = "--" ]; then
                    SECURITY="--"
                fi

                connect_network "$SSID" "$SECURITY"
            fi
            ;;
    esac
}

# Run menu
show_menu
