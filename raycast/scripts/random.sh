#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Random
# @raycast.mode compact
# @raycast.packageName Developer Utils

# Optional parameters:
# @raycast.icon 🔐
# @raycast.argument1 { "type": "text", "placeholder": "Length", "optional": true}
# @raycast.argument2 { "type": "dropdown", "placeholder": "Symbol", "optional": true, "data": [{"title": "Yes", "value": "true"}, {"title": "No", "value": "false"}]}

# Documentation:
# @raycast.author Sebastianus Kurniawan
# @raycast.authorURL https://github.com/sebastianusk
# @raycast.description Generate a strong password of requested character length with optional symbols

# check $1, if empty use 12
if [ -z "$1" ]
then
  length=12
else
  length=$1
fi

# check $2, if true add symbols
if [ "$2" == "true" ]
then
  pwgen -c -n -1 -y -s $length | pbcopy
else
  pwgen -c -n -1 -s $length | pbcopy
fi

echo "Password copied to clipboard!"
