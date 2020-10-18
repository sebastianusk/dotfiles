#!/bin/bash
# changeVolume

# Arbitrary but unique message id
msgId="991049"

# Change the volume using alsa(might differ if you use pulseaudio)
pulsemixer --change-volume $@

# Query amixer for the current volume and whether or not the speaker is muted
let "volume = $(pulsemixer --get-volume | awk '{print $1}') * 2 / 3"
mute="$(pulsemixer --get-mute)"
if [[ $volume == 0 || "$mute" == "1" ]]; then
    # Show the sound muted notification
    dunstify -a "changeVolume" -u low -i audio-volume-muted -r "$msgId" "Volume muted"
else
    # Show the volume notification
    dunstify -a "changeVolume" -u low -i audio-volume-high -r "$msgId" \
    "Volume: ${volume}%" "$(~/dotfiles/scripts/getProgressString.sh 10 "<b> </b>" "<b>  </b>" $volume)"
fi

# Play the volume changed sound
canberra-gtk-play -i audio-volume-change -d "changeVolume"
