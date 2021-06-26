function vault-edit --argument key
    set file (mktemp --suffix=.json)
    vault read -format=json $key | jq '.data' > $file
    $EDITOR $file
    vault write $key @$file
end
