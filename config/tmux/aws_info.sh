#!/bin/bash
source "$HOME/dotfiles/config/tmux/chip.sh"

aws_text="${AWS_PROFILE:---}"
[[ ${#aws_text} -gt 15 ]] && aws_text="${aws_text:0:15}"

chip "☁️" "$aws_text" "$CLR_PEACH"
