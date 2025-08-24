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

function vsplit --description "Start vsplit session with current multiplexer"
    if test "$MULTIPLEXER" = "tmux"
        tmuxinator start vsplit
    else if test "$MULTIPLEXER" = "zellij"
        zellij --layout vsplit
    else
        echo "No multiplexer configured"
    end
end
