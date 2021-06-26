function ec2 --description "fuzzy find ec2 instances & vsh into it"
    set ip (aws ec2 describe-instances --output text --filters Name=instance-state-name,Values=running --query "Reservations[].Instances[].[InstanceId,PrivateIpAddress,Tags[?Key=='Name']|[0].Value]" | fzf | awk '{print $2}')
    vsh root@$ip
    or vsh core@$ip
    or vsh ubuntu@$ip
end
