#!/bin/sh
surfraw -browser=vivaldi-stable $(sr -elvi | awk -F'-' '{print $1}' | sed '/:/d' | awk '{$1=$1};1' | rofi -kb-row-select "Ctrl-space" -kb-row-tab "Tab" -dmenu -i -p "search")
