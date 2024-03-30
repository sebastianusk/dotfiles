#!/bin/bash
if [[ -z "$1" ]]; then
  echo "no server provided"
  exit
fi

all=$(aws ssm get-inventory --profile $1 --filters Key=AWS:InstanceInformation.InstanceStatus,Values=Active)
selected=$(echo "$all" | jq '.Entities[]
| {id: .Id, ip: .Data."AWS:InstanceInformation".Content[0].IpAddress, name: .Data."AWS:InstanceInformation".Content[0].ComputerName}
| "\(.id) \(.ip) \(.name)"' | fzf)
if [[ -n "$selected" ]]; then
  id=$(echo "$selected" | tr -d '"' | cut -d' ' -f1)
  aws ssm start-session --target $id --profile $1
else
  echo "No server selected."
fi
