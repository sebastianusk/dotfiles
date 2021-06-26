function runningec2fzf () {
    aws ec2 describe-instances --output text --filters Name=instance-state-name,Values=running --query "Reservations[].Instances[].[InstanceId,PrivateIpAddress,Tags[?Key=='Name']|[0].Value]" | fzf
}
