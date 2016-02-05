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

# Checks if the given docker machine has the eth2 network adapter.
# This assumes that the eth2 network adapter is bridged to the host network:
has_bridged_interface() {
  docker-machine ssh "$1" ip link show eth2 > /dev/null 2>&1
}

validate_machine_name() {
  VBoxManage list vms | grep -w "\"$1\"" > /dev/null
}

init_machine_name() {
  MACHINE="${1:-default}"
  if ! validate_machine_name "$MACHINE"; then
    echo "Invalid machine name: $MACHINE" >&2
    exit 1
  fi
}

# Returns the bridged host interfaces available to the VirtualBox VM:
bridgedifs() {
  VBoxManage list bridgedifs | grep -w 'Name:' | sed 's/Name:[ \t]*//'
}

validate_network_adapter() {
  [ ! -z "$1" ] && bridgedifs | grep -w "$1" > /dev/null
}

print_bridgedifs_selection() {
  echo
  echo 'Please select the host network interface:'
  echo '===================='
  bridgedifs
  echo '===================='
}

select_network_adapter() {
  while ! validate_network_adapter "$NETWORK_ADAPTER"; do
    print_bridgedifs_selection && read -r NETWORK_ADAPTER
  done
  echo
}

# Stops the machine, executes the given command line and restarts the machine:
execute_and_restart() {
  docker-machine stop "$MACHINE" || true
  # Execute the given command line:
  "$@"
  docker-machine start "$MACHINE"
}

add_bridged_network_adapter() {
  echo "Adding bridged network adapter to $MACHINE VM ..."
  execute_and_restart \
    VBoxManage modifyvm "$MACHINE" \
      --nic3 bridged --bridgeadapter3 "$NETWORK_ADAPTER" --nictype3 82540EM
}

remove_bridged_network_adapter() {
  echo "Removing bridged network adapter from $MACHINE VM ..."
  execute_and_restart \
    VBoxManage modifyvm "$MACHINE" \
      --nic3 none
}

if [ "$1" = '-i' ]; then
  NETWORK_ADAPTER="$2"
  shift 2
fi

if [ "$1" = '-d' ]; then
  shift
  init_machine_name "$1"
  if has_bridged_interface "$MACHINE"; then
    remove_bridged_network_adapter >&2
  fi
else
  init_machine_name "$1"
  if ! has_bridged_interface "$MACHINE"; then
    select_network_adapter >&2
    add_bridged_network_adapter >&2
  fi
  docker_machine_bridged_ip "$MACHINE"
fi
