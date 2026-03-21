#!/bin/bash

# Now playing for sketchybar using MediaRemote framework
# Queries Control Center's Now Playing data directly

RESULT=$(
	osascript <<'APPLESCRIPT'
use framework "AppKit"
use framework "MediaRemote"

set MediaRemote to current application's NSBundle's bundleWithPath:"/System/Library/PrivateFrameworks/MediaRemote.framework/"
MediaRemote's load()

set MRNowPlayingRequest to current application's NSClassFromString("MRNowPlayingRequest")

try
    set infoDict to MRNowPlayingRequest's localNowPlayingItem()'s nowPlayingInfo()
    if infoDict is missing value then
        return "||"
    end if
    
    set theTitle to (infoDict's valueForKey:"kMRMediaRemoteNowPlayingInfoTitle") as text
    set theArtist to (infoDict's valueForKey:"kMRMediaRemoteNowPlayingInfoArtist") as text
    
    if theTitle is "" or theTitle is missing value then
        return "||"
    end if
    
    if theArtist is "" or theArtist is missing value then
        return theTitle & "||"
    end if
    
    return theTitle & " - " & theArtist & "||"
on error
    return "||"
end try
APPLESCRIPT
)

if [ -n "$RESULT" ] && [ "$RESULT" != "||" ]; then
	TRACK=$(echo "$RESULT" | cut -d'|' -f1)
	sketchybar --set media label="$TRACK" label.drawing=on icon=
else
	sketchybar --set media label.drawing=off icon=
fi
