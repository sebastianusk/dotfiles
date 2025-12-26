#!/usr/bin/env bash
#
# Walker Device Mount Menu
# Manage mounting and unmounting of removable devices
#

# Get list of mountable devices (exclude loop, ram, and system partitions)
get_devices() {
    lsblk -nrpo "name,type,size,mountpoint,label,fstype" | \
    awk '
    $2 == "part" || $2 == "disk" {
        name = $1
        type = $2
        size = $3
        mount = $4
        label = $5
        fstype = $6

        # Skip if no filesystem
        if (fstype == "" || fstype == "swap") next

        # Skip system partitions (root, boot, home)
        if (mount == "/" || mount == "/boot" || mount == "/home" || mount == "/nix/store") next

        # Format output
        if (mount != "") {
            # Mounted
            if (label != "") {
                printf "🟢 %s (%s) - %s @ %s\n", label, name, size, mount
            } else {
                printf "🟢 %s - %s @ %s\n", name, size, mount
            }
        } else {
            # Unmounted
            if (label != "") {
                printf "⚪ %s (%s) - %s\n", label, name, size
            } else {
                printf "⚪ %s - %s\n", name, size
            }
        }
    }'
}

# Mount a device
mount_device() {
    device="$1"

    # Try to mount with udisksctl
    if output=$(udisksctl mount -b "$device" 2>&1); then
        # Extract mount point from output
        mount_point=$(echo "$output" | grep -oP 'at \K.*')
        echo "✓ Mounted $device at $mount_point" | walker --dmenu
    else
        echo "✗ Failed to mount $device: $output" | walker --dmenu
    fi
}

# Unmount a device
unmount_device() {
    device="$1"

    # Try to unmount with udisksctl
    if output=$(udisksctl unmount -b "$device" 2>&1); then
        echo "✓ Unmounted $device" | walker --dmenu
    else
        echo "✗ Failed to unmount $device: $output" | walker --dmenu
    fi
}

# Main menu
show_menu() {
    # Get device list
    devices=$(get_devices)

    if [ -z "$devices" ]; then
        echo "No mountable devices found" | walker --dmenu
        exit 0
    fi

    # Add refresh option
    divider="─────────────────"
    options="$devices\n$divider\n🔄 Refresh"

    # Show menu
    chosen=$(echo -e "$options" | walker --dmenu)

    # Handle selection
    case "$chosen" in
        ""|"$divider")
            exit 0
            ;;
        "🔄 Refresh")
            show_menu
            ;;
        *)
            # Device selected
            if echo "$chosen" | grep -q "^🟢"; then
                # Mounted device - extract device path
                device=$(echo "$chosen" | grep -oP '\(/dev/[^)]+\)' | tr -d '()')
                if [ -z "$device" ]; then
                    # No label, device path is first field after icon
                    device=$(echo "$chosen" | awk '{print $2}')
                fi
                unmount_device "$device"
            elif echo "$chosen" | grep -q "^⚪"; then
                # Unmounted device - extract device path
                device=$(echo "$chosen" | grep -oP '\(/dev/[^)]+\)' | tr -d '()')
                if [ -z "$device" ]; then
                    # No label, device path is first field after icon
                    device=$(echo "$chosen" | awk '{print $2}')
                fi
                mount_device "$device"
            fi
            ;;
    esac
}

# Run menu
show_menu
