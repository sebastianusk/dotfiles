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

function ap --description "AWS Profile selector with fzf and SSO login"
    # Check if AWS CLI is available
    if not command -v aws >/dev/null 2>&1
        echo "❌ AWS CLI not found. Please install it first."
        return 1
    end

    # Check if fzf is available
    if not command -v fzf >/dev/null 2>&1
        echo "❌ fzf not found. Please install it first."
        return 1
    end

    # Check if AWS config file exists
    if not test -f ~/.aws/config
        echo "❌ AWS config file not found at ~/.aws/config"
        return 1
    end

    echo "🔍 Loading profile information from ~/.aws/config..."
    
    # Parse AWS config file and format for fzf
    set selection (awk '
        /^\[profile / {
            if (profile != "") {
                printf "%-20s %-15s %s\n", profile, account_id, region
            }
            profile = $2
            gsub(/\]/, "", profile)
            account_id = "unknown"
            region = "unknown"
        }
        /^sso_account_id/ && profile != "" { account_id = $3 }
        /^region/ && profile != "" { region = $3 }
        END {
            if (profile != "") {
                printf "%-20s %-15s %s\n", profile, account_id, region
            }
        }
    ' ~/.aws/config | fzf \
        --prompt="Select AWS Profile: " \
        --height=40% \
        --border \
        --header="Profile              Account ID      Region")
    
    if test -z "$selection"
        echo "❌ No profile selected."
        return 1
    end

    # Extract just the profile name (first column)
    set selected_profile (echo $selection | awk '{print $1}')
    
    echo "🔄 Setting AWS profile to: $selected_profile"
    
    # Set the AWS profile
    set -gx AWS_PROFILE $selected_profile
    
    # Test if the session is valid by trying to get caller identity
    echo "🔍 Testing AWS session..."
    
    if aws sts get-caller-identity >/dev/null 2>&1
        echo "✅ AWS session is valid!"
        echo "👤 Current identity:"
        aws sts get-caller-identity --output table
        
        # Show current profile info
        echo ""
        echo "📋 Profile: $AWS_PROFILE"
        set region (aws configure get region --profile $AWS_PROFILE 2>/dev/null)
        if test -n "$region"
            echo "🌍 Region: $region"
        end
    else
        echo "❌ AWS session invalid or expired. Running SSO login..."
        
        # Run SSO login for the selected profile
        aws sso login --profile $selected_profile
        
        # Test again after login
        if aws sts get-caller-identity >/dev/null 2>&1
            echo "✅ AWS SSO login successful!"
            echo "👤 Current identity:"
            aws sts get-caller-identity --output table
        else
            echo "❌ AWS SSO login failed. Please check your configuration."
            return 1
        end
    end
    
    # Refresh the shell prompt to show the new AWS profile
    echo "🔄 Refreshing shell prompt..."
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
