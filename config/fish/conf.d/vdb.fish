function vdb --argument role --description "Create DB connection session for vault"
    set conf (vault read -format=json database/config/(echo $role | cut -d '-' -f -3) )
    echo $conf | jq .data.connection_details.connection_url
    set res (vault read -format=json database/creds/$role)
    echo $res | jq '.data'
    read --prompt-str='[Enter] to end session' null
    vault lease revoke (echo $res | jq -r '.lease_id')
end
