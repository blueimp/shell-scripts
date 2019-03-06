#!/bin/sh

#
# Updates hostnames for the given IP or 127.0.0.1 in /etc/hosts.
#
# Usage: ./hostnames.sh [-i IP] [config_file_1] [config_file_2] [...]
#
# The default configuration file is "$PWD/hostnames".
#
# If the provided IP string is empty, the hostname entries are removed.
#
# Each hostname in the configuration files must be separated by a new line.
# Empty lines and lines starting with a hash (#) will be ignored.
#
# Copyright 2015, Sebastian Tschan
# https://blueimp.net
#
# Licensed under the MIT license:
# https://opensource.org/licenses/MIT
#

set -e

if [ "$1" = '-i' ]; then
  IP=$2
  shift 2
else
  IP=127.0.0.1
fi

if [ $# = 0 ]; then
  # Use "$PWD/hostnames" as default configuration file:
  set -- "$PWD/hostnames"
fi

# Replaces everything but alphanumeric characters with dashes:
sanitize() {
  echo "$1" | sed 's/[^a-zA-Z0-9-]/-/g'
}

# Returns a marker to identify the hostname settings in /etc/hosts:
marker() {
  # Use the config file folder as project name:
  project="$(sanitize "$(basename "$(cd "$(dirname "$1")" && pwd)")")"
  config_name="$(sanitize "$(basename "$1")")"
  echo "## $project $config_name"
}

# Updates hosts from STDIN with the mappings in the given config file:
map_hostnames() {
  marker_base="$(marker "$1")"
  marker_start="$marker_base start"
  marker_end="$marker_base end"
  # Remove the current hostnames section:
  sed "/$marker_start/,/$marker_end/d"
  # Don't add any entries unless IP is set:
  if [ -z "$IP" ]; then return; fi
  # Add the new hostname settings:
  echo "$marker_start"
  while read -r line; do
    # Skip empty lines and lines starting with a hash (#):
    if [ -z "$line" ] || [ "${line#\#}" != "$line" ]; then continue; fi
    # Add each hostname entry with the $IP as mapping:
    printf '%s\t%s\n' "$IP" "$line"
  done < "$1"
  echo "$marker_end"
}

get_hosts_content() {
  # Retrieve the current host settings:
  hosts_content="$(cat /etc/hosts)"
  for file; do
    if [ ! -f "$file" ]; then
      echo "$file is not a valid file." >&2
      continue
    fi
    # Update the mappings for each configuration file:
    hosts_content="$(echo "$hosts_content" | map_hostnames "$file")"
  done
  echo "$hosts_content"
}

# Updates /etc/hosts with the given content after confirmation from the user:
update_hosts() {
  hosts_content="$1"
  # Diff /etc/hosts with the new content:
  if hosts_diff="$(echo "$hosts_content" | diff /etc/hosts -)"; then
    echo 'No updates to /etc/hosts required.'
    return
  fi
  # Show a confirmation prompt to the user:
  echo
  echo "$hosts_diff"
  echo
  echo 'Update /etc/hosts with the given changes?'
  echo 'This will require Administrator privileges.'
  echo 'Please type "y" if you wish to proceed.'
  read -r confirmation
  if [ "$confirmation" = "y" ]; then
    # Check if we have root access:
    if [ "$(id -u)" -eq 0 ]; then
      echo "$hosts_content" > /etc/hosts
    else
      # Get root access and then write the new hosts file:
      echo "$hosts_content" | sudo tee /etc/hosts > /dev/null
    fi
    # Check if the last command failed:
    # shellcheck disable=SC2181
    if [ $? -eq 0 ]; then
      echo "Successfully updated /etc/hosts."
      return
    else
      echo "Update of /etc/hosts failed." >&2
      return 1
    fi
  fi
  echo "No updates to /etc/hosts written."
}

update_hosts "$(get_hosts_content "$@")"
