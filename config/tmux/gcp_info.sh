#!/bin/bash
source "$HOME/dotfiles/config/tmux/chip.sh"

gcp_text="---"
if command -v gcloud >/dev/null 2>&1; then
	gcp_text=$(gcloud config get project 2>/dev/null)
	[[ -z "$gcp_text" || "$gcp_text" == "(unset)" ]] && gcp_text="---"
	[[ ${#gcp_text} -gt 15 ]] && gcp_text="${gcp_text:0:15}"
fi

chip "🌐" "$gcp_text" "$CLR_SKY"
