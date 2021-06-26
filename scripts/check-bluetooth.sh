#/bin/sh
bluetoothctl -- show | grep -i Powered: | awk '{
if ($2 == "yes")
    print "on"
else print "off"
}'
