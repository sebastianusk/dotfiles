# Custom Zsh Functions

# AWS Profile selector with fzf and SSO login
function ap() {
    # Check if AWS CLI is available
    if ! command -v aws >/dev/null 2>&1; then
        echo "❌ AWS CLI not found. Please install it first."
        return 1
    fi

    # Check if fzf is available
    if ! command -v fzf >/dev/null 2>&1; then
        echo "❌ fzf not found. Please install it first."
        return 1
    fi

    # Check if AWS config file exists
    if [ ! -f ~/.aws/config ]; then
        echo "❌ AWS config file not found at ~/.aws/config"
        return 1
    fi

    echo "🔍 Loading profile information from ~/.aws/config..."

    # Parse AWS config file and format for fzf
    local selection=$(awk '
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

    if [ -z "$selection" ]; then
        echo "❌ No profile selected."
        return 1
    fi

    # Extract just the profile name (first column)
    local selected_profile=$(echo "$selection" | awk '{print $1}')

    echo "🔄 Setting AWS profile to: $selected_profile"

    # Set the AWS profile
    export AWS_PROFILE="$selected_profile"

    # Test if the session is valid by trying to get caller identity
    echo "🔍 Testing AWS session..."

    if aws sts get-caller-identity >/dev/null 2>&1; then
        echo "✅ AWS session is valid!"
        echo "👤 Current identity:"
        aws sts get-caller-identity --output table

        # Show current profile info
        echo ""
        echo "📋 Profile: $AWS_PROFILE"
        local region=$(aws configure get region --profile "$AWS_PROFILE" 2>/dev/null)
        if [ -n "$region" ]; then
            echo "🌍 Region: $region"
        fi
    else
        echo "❌ AWS session invalid or expired. Running SSO login..."

        # Run SSO login for the selected profile
        aws sso login --profile "$selected_profile"

        # Test again after login
        if aws sts get-caller-identity >/dev/null 2>&1; then
            echo "✅ AWS SSO login successful!"
            echo "👤 Current identity:"
            aws sts get-caller-identity --output table
        else
            echo "❌ AWS SSO login failed. Please check your configuration."
            return 1
        fi
    fi
}

# Change directory to git repository root
function cdg() {
    local toplevel=$(git rev-parse --show-toplevel 2>/dev/null)
    if [[ $? -eq 0 ]]; then
        cd "$toplevel"
    else
        echo "Not in a git repository"
        return 1
    fi
}

# Expand or extract bundled & compressed files
function extract() {
    if [ $# -eq 0 ]; then
        echo "Usage: extract <file>"
        return 1
    fi

    local file="$1"
    if [ ! -f "$file" ]; then
        echo "File not found: $file"
        return 1
    fi

    local ext="${file##*.}"

    case "$ext" in
        tar)
            tar -xvf "$file"
            ;;
        gz)
            if [[ "$file" == *.tar.gz ]]; then
                tar -zxvf "$file"
            else
                gunzip "$file"
            fi
            ;;
        tgz)
            tar -zxvf "$file"
            ;;
        bz2)
            tar -jxvf "$file"
            ;;
        rar)
            unrar x "$file"
            ;;
        zip)
            unzip "$file"
            ;;
        *)
            echo "Unknown extension: $ext"
            return 1
            ;;
    esac
}

# AWS SSM Session Manager helper
function ssm-agent() {
    if [[ -z "$1" ]]; then
        echo "no server provided"
        return 1
    fi

    local all=$(aws ssm get-inventory --profile $1 --filters Key=AWS:InstanceInformation.InstanceStatus,Values=Active)
    local selected=$(echo "$all" | jq '.Entities[]
    | {id: .Id, ip: .Data."AWS:InstanceInformation".Content[0].IpAddress, name: .Data."AWS:InstanceInformation".Content[0].ComputerName}
    | "\(.id) \(.ip) \(.name)"' | fzf)

    if [[ -n "$selected" ]]; then
        local id=$(echo "$selected" | tr -d '"' | cut -d' ' -f1)
        aws ssm start-session --target $id --profile $1
    else
        echo "No server selected."
    fi
}

# Create timestamped temporary file in /tmp/files
function tmpa() {
    if [ ! -d "/tmp/files" ]; then
        mkdir -p /tmp/files
    fi

    local file=$(date +"%y-%m-%d_%T")
    if [ -n "$1" ]; then
        file="${file}.$1"
    fi

    file="/tmp/files/$file"
    nvim "$file"
}

# Find and edit files in /tmp/files using fzf
function tmpl() {
    if [ ! -d "/tmp/files" ]; then
        echo "No temporary files directory found"
        return 1
    fi

    if ! command -v fzf >/dev/null 2>&1; then
        echo "fzf not found"
        return 1
    fi

    local result=$(ls /tmp/files 2>/dev/null | fzf --prompt="Select temp file: ")
    if [ -n "$result" ]; then
        nvim "/tmp/files/$result"
    fi
}

# Create a temporary directory and enter it
function tmpd() {
    local dir
    # Use a fixed prefix and date/random suffix for a predictable, safe name
    # mktemp --tmpdir creates it in the system temp directory
    dir=$(mktemp -d "${TMPDIR:-/tmp}/tmpd_XXXXXX")
    cd "$dir" || return
    echo "📂 Temporary directory: $dir"
}

# Start vsplit session with current multiplexer
function vsplit() {
    if [ "$MULTIPLEXER" = "tmux" ]; then
        tmuxinator start vsplit
    elif [ "$MULTIPLEXER" = "zellij" ]; then
        zellij --layout vsplit
    else
        echo "No multiplexer configured"
        return 1
    fi
}

# Quick gcloud project switcher
function gcp() {
    if ! command -v gcloud >/dev/null 2>&1; then
        echo "❌ gcloud CLI not found. Please install it first."
        return 1
    fi

    if ! command -v fzf >/dev/null 2>&1; then
        echo "❌ fzf not found. Please install it first."
        return 1
    fi

    local project=$(gcloud projects list --format="value(projectId)" | fzf --height 40% --reverse --header "Select GCP Project")
    if [[ -n "$project" ]]; then
        gcloud config set project "$project"
        echo "✓ Active project set to: $project"
    fi
}

# GKE Cluster Management: Sync local kubectl with GCP clusters
function gkeproj() {
    if ! command -v gcloud >/dev/null 2>&1; then
        echo "❌ gcloud CLI not found. Please install it first."
        return 1
    fi
    if ! command -v kubectl >/dev/null 2>&1; then
        echo "❌ kubectl not found. Please install it first."
        return 1
    fi
    if ! command -v fzf >/dev/null 2>&1; then
        echo "❌ fzf not found. Please install it first."
        return 1
    fi

    local project=$(gcloud config get-value project 2>/dev/null)
    if [[ -z "$project" ]]; then
        echo "❌ No active gcloud project set. Run 'gcp' first."
        return 1
    fi

    echo "🔍 Checking GKE clusters in project: $project..."

    # Get local contexts
    local local_contexts=$(kubectl config get-contexts -o name 2>/dev/null)

    # Get remote clusters (format: name location status)
    local remote_clusters_raw=$(gcloud container clusters list --format="value(name,location,status)" 2>/dev/null)

    if [[ -z "$remote_clusters_raw" ]]; then
        echo "ℹ️ No GKE clusters found in project $project."
        return 0
    fi

    local missing_clusters=()
    while read -r name location c_status; do
        [[ -z "$name" ]] && continue
        [[ "$c_status" != "RUNNING" ]] && continue

        # Construct the expected context name
        local context_name="gke_${project}_${location}_${name}"

        if ! echo "$local_contexts" | grep -q "^${context_name}$"; then
            missing_clusters+=("$name $location")
        fi
    done <<< "$remote_clusters_raw"

    if [[ ${#missing_clusters[@]} -eq 0 ]]; then
        echo "✅ All running clusters in $project are already in your local kubectl config."
    elif [[ ${#missing_clusters[@]} -eq 1 ]]; then
        local c_info=(${(s: :)missing_clusters[1]})
        local c_name=${c_info[1]}
        local c_loc=${c_info[2]}

        echo -n "❓ Found missing cluster: $c_name ($c_loc). Add to local config? [y/N] "
        read -k 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            gcloud container clusters get-credentials "$c_name" --location "$c_loc" --project "$project"
        fi
    else
        echo "❓ Found multiple missing clusters. Select which ones to add:"
        local selected=$(printf "%s\n" "${missing_clusters[@]}" | fzf -m --header "Select clusters to add (Tab to multi-select)" --height 40%)

        if [[ -n "$selected" ]]; then
            while read -r c_name c_loc; do
                echo "🔄 Adding $c_name ($c_loc)..."
                gcloud container clusters get-credentials "$c_name" --location "$c_loc" --project "$project"
            done <<< "$selected"
        fi
    fi

    echo "\n📋 Current local GKE clusters:"
    kubectl config get-contexts | grep "^*" | grep "gke_${project}" || kubectl config get-contexts | grep "gke_${project}"
}
