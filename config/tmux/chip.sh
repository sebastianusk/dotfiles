#!/bin/bash

# Catppuccin Mocha colors
CLR_BG="#1e1e2e"       # The main background color of your Tmux bar
CLR_TEAL="#94e2d5"
CLR_SURFACE0="#313244"
CLR_CRUST="#11111b"
CLR_TEXT="#cdd6f4"

# U+E0B6 is the standard "Left Half Circle"
LEFT_SEP=$'\xee\x82\xb6'

chip() {
    local icon="$1"
    local text="$2"
    local icon_bg="$3"

    # 1. THE CAP: FG is the icon color, BG is the bar background (CLR_BG)
    # 2. THE ICON: FG is dark (Crust), BG is the icon color
    # 3. THE TEXT: FG is light, BG is Surface0
    # 4. THE END: Reset or add a small space

    printf "#[fg=%s,bg=%s]%s#[fg=%s,bg=%s] %s #[fg=%s,bg=%s] %s " \
        "$icon_bg" "$CLR_BG" "$LEFT_SEP" \
        "$CLR_CRUST" "$icon_bg" "$icon" \
        "$CLR_TEXT" "$CLR_SURFACE0" "$text"
}

# Example usage:
# chip "󰭦" "Messages" "$CLR_TEAL"
