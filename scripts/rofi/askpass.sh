#!/bin/sh
rofi -dmenu \
	-password \
	-no-fixed-num-lines \
	-p "$(printf "$1" | sed s/://)"
