function vdb --argument role --description "Create DB connection session for vault"
    set conf (vault read -format=json database/config/(echo $role | cut -d '-' -f -3) )
    echo $conf | jq .data.connection_details.connection_url
    set res (vault read -format=json database/creds/$role)
    echo $res | jq '.data'
    read --prompt-str='[Enter] to end session' null
    vault lease revoke (echo $res | jq -r '.lease_id')
end


function vrole -d 'Connect to a database with vault role'
    set role (vault list -format json database/roles | jq -r '.[]' | fzf)

    set conf (vault read -format=json database/config/(echo $role | cut -d '-' -f -3 ))
    set res (vault read -format=json database/creds/$role)

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

function vsh --description 'Vault SSH alias'
  vault ssh -role=sre -mode ca $argv;
end


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

function cdg
  set -lx TOPLEVEL (git rev-parse --show-toplevel)
    if test $status -eq 0
      cd $TOPLEVEL
  end
end
