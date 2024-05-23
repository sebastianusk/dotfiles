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

# Taken from: https://github.com/dideler/dotfiles/blob/master/functions/extract.fish
function extract --description "Expand or extract bundled & compressed files"
  set --local ext (echo $argv[1] | awk -F. '{print $NF}')
  switch $ext
    case tar  # non-compressed, just bundled
      tar -xvf $argv[1]
    case gz
      if test (echo $argv[1] | awk -F. '{print $(NF-1)}') = tar  # tar bundle compressed with gzip
        tar -zxvf $argv[1]
      else  # single gzip
        gunzip $argv[1]
      end
    case tgz  # same as tar.gz
      tar -zxvf $argv[1]
    case bz2  # tar compressed with bzip2
      tar -jxvf $argv[1]
    case rar
      unrar x $argv[1]
    case zip
      unzip $argv[1]
    case '*'
      echo "unknown extension"
  end
end

function obsidian_today
    echo "~/obsidian/$(date +%Y-%m-%d).md"
end
abbr -a ot --position anywhere --function obsidian_today

function rec --description "Run asciinema rec"
  set file $(date +"%y-%m-%d_%T")
  if count $argv[1] > /dev/null
    set file ( string join '' $file '-' $argv[1] )
  end
  set file ( string join '' "$HOME/asciinema/" $file '.cast')
  asciinema rec $file
end

function fzf-rec --description "Search asciinema rec"
  ls ~/asciinema | fzf
end

function rec-ot --description "select rect and add to obsidian today"
  fzf-rec | read -l result; and asciinema cat ~/asciinema/$result | sed -e 's/\x1b\[[0-9;]*m//g' >> cuk
end

function tmpa --description "create tmp file on /tmp/files"
  if not test -d /tmp/files/
    mkdir /tmp/files
  end
  set file $(date +"%y-%m-%d_%T")
  if count $argv[1] > /dev/null
    set file ( string join '' $file '.' $argv[1])
  end
  set file (string join '' "/tmp/files/" $file)
  nvim $file
end

function tmpl --description "find and edit the files on /tmp/files"
  ls /tmp/files | fzf | read -l result; and nvim /tmp/files/$result
end

function sudo
    if test "$argv" = !!
        eval command sudo $history[1]
    else
        command sudo $argv
    end
end
