#!/bin/sh

#
# Returns the private IP of the EC2 instance with the given "Name" tag.
#
# For multiple instances with the same name, an index after the name indicates
# for which instance the private IP address should be returned.
# e.g. "name" and "name0" return the first, "name1" the second, etc.
#
# Usage: ./aws-ec2-private-ip.sh name[index]
#
# Example `~/.ssh/config` for an SSH Bastion setup:
#
# ```
# Host bastion
#   User ec2-user
#   HostName bastion.example.org
# 
# Host apple* banana* orange*
#   User ec2-user
#   ProxyCommand ssh -W $(/path/to/aws-ec2-private-ip.sh '%h'):%p bastion
# ```
#
# With this config, each host can be connected to via their "name[index]".
# e.g. `ssh banana2`
#

set -e

NAME=${1:?}

aws ec2 describe-instances \
  --no-paginate \
  --filters "Name=tag:Name,Values=$(echo "$NAME" | sed 's/[0-9]//g')" \
  --output text --query 'Reservations[*].Instances[*].PrivateIpAddress' |
  awk "NR==$(($(echo "$NAME" | sed 's/[^0-9]//g')+1))"
