#!/usr/bin/env bash
#
# Walker Bluetooth Menu
# Adapted from rofi-bluetooth script by Nick Clyde (clydedroid)
#
# A script that generates a walker menu that uses bluetoothctl to
# connect to bluetooth devices and display status info.
#

# PID file for scan process
SCAN_PID_FILE="/tmp/bluetooth-scan.pid"

# Checks if bluetooth controller is powered on
power_on() {
    if bluetoothctl show | grep -q "Powered: yes"; then
        return 0
    else
        return 1
    fi
}

# Toggles power state
toggle_power() {
    if power_on; then
        bluetoothctl power off
        show_menu
    else
        bluetoothctl power on
        show_menu
    fi
}

# Checks if controller is scanning for new devices
scan_on() {
    if bluetoothctl show | grep -q "Discovering: yes"; then
        echo "🔍 Scan: on"
        return 0
    else
        echo "🔍 Scan: off"
        return 1
    fi
}

# Toggles scanning state
toggle_scan() {
    if scan_on; then
        # Stop scanning
        if [ -f "$SCAN_PID_FILE" ]; then
            SCAN_PID=$(cat "$SCAN_PID_FILE" 2>/dev/null)
            if [ -n "$SCAN_PID" ]; then
                kill "$SCAN_PID" 2>/dev/null
            fi
            rm -f "$SCAN_PID_FILE"
        fi
        pkill -f "bluetoothctl" 2>/dev/null
        sleep 0.5
        show_menu
    else
        # Start scanning - keep bluetoothctl alive with stdin open
        # This is the key: bluetoothctl needs to stay running for scan to work
        (echo "scan on"; sleep 3600) | bluetoothctl >/dev/null 2>&1 &
        echo $! > "$SCAN_PID_FILE"
        # Give it time to start discovering
        sleep 3
        show_menu
    fi
}

# Checks if controller is able to pair to devices
pairable_on() {
    if bluetoothctl show | grep -q "Pairable: yes"; then
        echo "📱 Pairable: on"
        return 0
    else
        echo "📱 Pairable: off"
        return 1
    fi
}

# Toggles pairable state
toggle_pairable() {
    if pairable_on; then
        bluetoothctl pairable off
        show_menu
    else
        bluetoothctl pairable on
        show_menu
    fi
}

# Checks if a device is connected
device_connected() {
    device_info=$(bluetoothctl info "$1")
    if echo "$device_info" | grep -q "Connected: yes"; then
        return 0
    else
        return 1
    fi
}

# Toggles device connection
toggle_connection() {
    if device_connected $1; then
        bluetoothctl disconnect $1
        show_menu
    else
        bluetoothctl connect $1
        show_menu
    fi
}

# Checks if a device is paired
device_paired() {
    device_info=$(bluetoothctl info "$1")
    if echo "$device_info" | grep -q "Paired: yes"; then
        echo "🔗 Paired: yes"
        return 0
    else
        echo "🔗 Paired: no"
        return 1
    fi
}

# Toggles device paired state
toggle_paired() {
    if device_paired $1; then
        bluetoothctl remove $1
        show_menu
    else
        bluetoothctl pair $1
        show_menu
    fi
}

# Checks if a device is trusted
device_trusted() {
    device_info=$(bluetoothctl info "$1")
    if echo "$device_info" | grep -q "Trusted: yes"; then
        echo "✓ Trusted: yes"
        return 0
    else
        echo "✓ Trusted: no"
        return 1
    fi
}

# Toggles device trust
toggle_trust() {
    if device_trusted $1; then
        bluetoothctl untrust $1
        show_menu
    else
        bluetoothctl trust $1
        show_menu
    fi
}

# A submenu for a specific device
device_menu() {
    device=$1

    # Get device name and mac address
    device_name=$(echo $device | cut -d ' ' -f 3-)
    mac=$(echo $device | cut -d ' ' -f 2)

    # Build options
    if device_connected $mac; then
        connected="🔵 Connected: yes"
    else
        connected="⚪ Connected: no"
    fi
    paired=$(device_paired $mac)
    trusted=$(device_trusted $mac)
    options="$connected\n$paired\n$trusted\n← Back"

    # Open walker menu
    chosen="$(echo -e "$options" | walker --dmenu)"

    # Match chosen option to command
    case $chosen in
        "")
            show_menu
            ;;
        *"Connected:"*)
            toggle_connection $mac
            ;;
        *"Paired:"*)
            toggle_paired $mac
            ;;
        *"Trusted:"*)
            toggle_trust $mac
            ;;
        "← Back")
            show_menu
            ;;
    esac
}

# Main menu
show_menu() {
    # Get menu options
    if power_on; then
        power="⚡ Power: on"

        # List devices
        devices=$(bluetoothctl devices | grep Device | cut -d ' ' -f 3-)

        # Add connected indicator
        device_list=""
        while IFS= read -r device_name; do
            if [ -n "$device_name" ]; then
                mac=$(bluetoothctl devices | grep "$device_name" | cut -d ' ' -f 2)
                if device_connected $mac; then
                    device_list="${device_list}🔵 ${device_name}\n"
                else
                    device_list="${device_list}⚪ ${device_name}\n"
                fi
            fi
        done <<< "$devices"

        # Get controller flags
        scan=$(scan_on)
        pairable=$(pairable_on)
        divider="─────────"

        # Build options
        if [ -n "$device_list" ]; then
            options="${device_list}${divider}\n$power\n$scan\n$pairable"
        else
            options="$power\n$scan\n$pairable"
        fi
    else
        power="⚡ Power: off"
        options="$power"
    fi

    # Open walker menu
    chosen="$(echo -e "$options" | walker --dmenu)"

    # Match chosen option to command
    case $chosen in
        "" | "$divider")
            exit 0
            ;;
        *"Power:"*)
            toggle_power
            ;;
        *"Scan:"*)
            toggle_scan
            ;;
        *"Pairable:"*)
            toggle_pairable
            ;;
        *)
            # Device selected - open submenu
            device_name=$(echo "$chosen" | sed 's/^[🔵⚪] //')
            device=$(bluetoothctl devices | grep "$device_name")
            if [[ $device ]]; then
                device_menu "$device"
            fi
            ;;
    esac
}

# Run menu
show_menu
