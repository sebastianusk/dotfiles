#!/bin/sh

set -e

HDMI_STATUS=$(</sys/class/drm/card0-HDMI-A-1/status )

if [ "connected" == "$HDMI_STATUS" ]; then
    xrandr --output eDP1 --mode 1600x900 --pos 1920x0 --rotate normal
    xrandr --output HDMI1 --auto --primary --mode 1920x1080 --pos 0x0 --rotate normal
else
    xrandr --output eDP1 --primary --mode 1920x1080 --pos 0x0 --rotate normal
fi
