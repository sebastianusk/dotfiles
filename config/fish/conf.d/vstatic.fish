function vstatic -d 'Connect to a database using vault static role (admin)'
    set role (vault list -format json database/static-roles | jq -r '.[]' | fzf)

    set conf (vault read -format=json database/config/(echo $role | cut -d '-' -f -3 ))
    set res (vault read -format=json database/static-creds/$role)

    set connstring0 (echo $conf | jq -r .data.connection_details.connection_url)

    set host (echo $connstring0 | cut -d '@' -f 2 | cut -d ':' -f 1 )

    set username (echo $res | jq -r '.data.username')
    set password (echo $res | jq -r '.data.password')

    set connstring (echo $connstring0 \
        | sed "s/{{username}}/$username/g" \
        | sed "s/{{password}}/$password/g"
    )

    set domain (string match --regex --entire '^[\d\.]+$' $host)

    if test -z "$domain"
        set ip (dig +short @10.128.0.12 $host A)
        set connstring (echo $connstring | sed "s/$host/$ip/g")
    end

    pgcli $connstring
end
