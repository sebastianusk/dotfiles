#!/bin/sh

MEM=$(ps -Ao %mem | awk '{s+=$1} END {printf "%.0f", s}')
sketchybar --set "$NAME" label="${MEM}%"
