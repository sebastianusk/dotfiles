#!/usr/bin/env bash

# Walker Power Menu Script
# Provides shutdown, reboot, and suspend options

items="⏻ Shutdown\n⭮ Reboot\n⏾ Suspend"
output=$(echo -e "$items" | walker --dmenu)

case "$output" in
    "⏻ Shutdown")
        systemctl poweroff
        ;;
    "⭮ Reboot")
        systemctl reboot
        ;;
    "⏾ Suspend")
        systemctl suspend
        ;;
esac
