#!/bin/sh

#
# Adds a bridged network adapter to a VirtualBox docker machine.
#
# If the "-d" argument is given, the bridged network adapter is removed.
# The host network adapter can be provided via "-i network_adapter" argument.
# The machine name can be provided as last argument, else "default" is used.
#
# Usage: ./docker-machine-bridge.sh [-i network_adapter] [-d] [machine]
#
# Copyright 2016, Sebastian Tschan
# https://blueimp.net
#
# Licensed under the MIT license:
# http://www.opensource.org/licenses/MIT
#

# Exit immediately if a command exits with a non-zero status:
set -e

# Returns the IP of the eth2 network adapter of the given docker machine.
# This assumes that the eth2 network adapter is bridged to the host network:
docker_machine_bridged_ip() {
  docker-machine ssh "$1" \
    ip -4 addr show dev eth2 scope global | sed 's#/.*##' |
    grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}'
}

# Returns the bridged host interfaces available to the VirtualBox VM:
bridgedifs() {
  VBoxManage list bridgedifs | grep -w 'Name:' | sed 's/Name:[ \t]*//'
}

print_bridgedifs_selection() {
  echo
  echo 'Please select the host network interface:'
  echo '===================='
  bridgedifs
  echo '===================='
}

validate_machine_name() {
  VBoxManage list vms | grep -w "\"$MACHINE\"" > /dev/null
}

validate_network_adapter() {
  [ ! -z "$NETWORK_ADAPTER" ] && bridgedifs |
    grep -w "$NETWORK_ADAPTER" > /dev/null
}

select_network_adapter() {
  while ! validate_network_adapter; do
    print_bridgedifs_selection && read -r NETWORK_ADAPTER
  done
}

add_bridged_network_adapter() {
  docker-machine stop "$MACHINE" || true
  echo "Adding bridged network adapter to $MACHINE VM ..."
  VBoxManage modifyvm "$MACHINE" --nic3 bridged \
    --bridgeadapter3 "$NETWORK_ADAPTER"
  docker-machine start "$MACHINE"
}

remove_bridged_network_adapter() {
  docker-machine stop "$MACHINE" || true
  echo "Removing bridged network adapter from $MACHINE VM ..."
  VBoxManage modifyvm "$MACHINE" --nic3 none
  docker-machine start "$MACHINE"
}

if [ "$1" = '-i' ]; then
  NETWORK_ADAPTER="$2"
  shift 2
fi

if [ "$1" = '-d' ]; then
  shift
  MACHINE="${1:-default}"
  remove_bridged_network_adapter >&2
  exit
fi

MACHINE="${1:-default}"

validate_machine_name || (echo "Invalid machine name: $MACHINE" >&2 && exit 1)

IP="$(docker_machine_bridged_ip "$MACHINE" 2> /dev/null || true)"

if [ -z "$IP" ]; then
  select_network_adapter >&2
  add_bridged_network_adapter >&2
  # Wait for the machine to retrieve its IP from the DHCP server:
  sleep 2
  IP="$(docker_machine_bridged_ip "$MACHINE")"
fi

echo "$IP"
