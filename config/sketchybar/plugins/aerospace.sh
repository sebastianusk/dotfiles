#!/usr/bin/env bash

WS="$1"

# Use the item name that sketchybar provides ($NAME)
# This is the correct item to update regardless of how it's named

# Highlight if this workspace is focused (change background color)
if [ "$WS" = "$FOCUSED_WORKSPACE" ]; then
	sketchybar --set "$NAME" background.color=0x44ffffff
else
	sketchybar --set "$NAME" background.color=0x15ffffff
fi

# Determine workspace icon based on windows
WINDOWS=$(aerospace list-windows --workspace "$WS" --json 2>/dev/null)
COUNT=$(echo "$WINDOWS" | jq 'length' 2>/dev/null || echo "0")

# Pad all icons to 2 characters for uniform width
if [ "$COUNT" -eq 0 ]; then
	ICON="○ "
elif [ "$COUNT" -eq 1 ]; then
	APP=$(echo "$WINDOWS" | jq -r '.[0]["app-name"]' 2>/dev/null)
	case "$APP" in
	*Google\ Chrome*) ICON=" " ;;
	*Alacritty*) ICON=" " ;;
	*Slack*) ICON=" " ;;
	*Obsidian*) ICON=" " ;;
	*Calendar*) ICON=" " ;;
	*Mail*) ICON=" " ;;
	*Kaset*) ICON=" " ;;
	*) ICON="● " ;;
	esac
else
	if [ "$COUNT" -lt 10 ]; then
		ICON="$COUNT "
	else
		ICON="$COUNT"
	fi
fi

sketchybar --set "$NAME" icon="$ICON"
