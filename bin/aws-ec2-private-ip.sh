#!/bin/sh

#
# Returns the private IP of the EC2 instance with the given tag.
# By default the Name tag is queried.
# A different tag key can be provided via --tag option.
#
# For multiple instances with the same tag, an index after the value indicates
# for which instance the private IP address should be returned.
# e.g. "name" and "name0" return the first, "name1" the second, etc.
#
# Usage: ./aws-ec2-private-ip.sh [--tag key] value[index]
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

if [ "$1" = --tag ]; then
  TAG=$2
  shift 2
else
  TAG=Name
fi

VALUE=$(echo "$1" | sed 's/[0-9]$//g')
INDEX=$((${1##$VALUE}+1))

aws ec2 describe-instances \
  --no-paginate \
  --filters "Name=tag:$TAG,Values=$VALUE" \
  --output text --query 'Reservations[*].Instances[*].PrivateIpAddress' |
  awk "NR==$INDEX"
