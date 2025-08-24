#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title prit
# @raycast.mode compact

# Optional parameters:
# @raycast.icon 🤖
# @raycast.argument1 { "type": "text", "placeholder": "command", "optional": true }

# Documentation:
# @raycast.description Connect to pritunl
# @raycast.author sebastianus_kurniawan
# @raycast.authorURL https://raycast.com/sebastianus_kurniawan

profile=xtkgsumlbuehevpt

if [[ "$1" == "d" ]]; then
  /Applications/Pritunl.app/Contents/Resources/pritunl-client stop "${profile}"
else
  op item get Pritunl --otp | xargs /Applications/Pritunl.app/Contents/Resources/pritunl-client start "${profile}" -p
fi
