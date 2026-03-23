#!/bin/sh

if [ -z "$INFO" ]; then
	INFO=$(osascript -e 'tell application "System Events" to get name of first process whose frontmost is true')
fi
sketchybar --set "$NAME" label="$INFO"
