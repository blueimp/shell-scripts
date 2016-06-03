#!/bin/sh

#
# Updates hostnames for the docker host IP or 127.0.0.1 in /etc/hosts.
# Usage: ./hostnames.sh [-d] [config_file_1] [config_file_2] [...]
#
# The default configuration file is "$PWD/hostnames".
#
# If the "-d" argument is given, the hostname entries are removed.
#
# Each hostname in the configuration file must be separated by a new line.
# Empty lines and lines starting with a hash (#) will be ignored.
#
# Copyright 2015, Sebastian Tschan
# https://blueimp.net
#
# Licensed under the MIT license:
# http://www.opensource.org/licenses/MIT
#

if [ "$1" = '-d' ]; then
	# An empty DOCKER_HOST_IP signifies the removal of the hostname entries:
	DOCKER_HOST_IP=''
	shift
elif [ -z "$DOCKER_HOST" ]; then
	# Use 127.0.0.1 as default docker host IP:
	DOCKER_HOST_IP='127.0.0.1'
else
	# Extract the docker host IP from the DOCKER_HOST url:
	DOCKER_HOST_IP="${DOCKER_HOST##*/}"
	DOCKER_HOST_IP="${DOCKER_HOST_IP%:*}"
fi

if [ $# = 0 ]; then
	# Without arguments, use "$PWD/hostnames" as default configuration file:
	set -- "$PWD/hostnames"
fi

# Normalizes according to docker-compose project naming rules:
normalize() {
	echo "$1" | tr '[A-Z]' '[a-z]' | sed s/[^a-z0-9]//g
}

# Returns a marker to identify the hostname settings in /etc/hosts:
marker() {
	# Use the config file folder as project name:
	local project="$(normalize "$(basename "$(cd "$(dirname "$1")" && pwd)")")"
	local config_name="$(normalize "$(basename "$1")")"
	echo "## $project $config_name"
}

# Updates hosts from STDIN with the mappings in the given config file:
map_hostnames() {
	local marker_base="$(marker "$1")"
	local marker_start="$marker_base start"
	local marker_end="$marker_base end"
	# Remove the current hostnames section:
	sed "/$marker_start/,/$marker_end/d"
	# Don't add any entries unless DOCKER_HOST_IP is set:
	[ -z "$DOCKER_HOST_IP" ] && return
	# Add the new hostname settings:
	echo "$marker_start"
	local line
	while read line; do
		# Skip empty lines and lines starting with a hash (#):
	  ([ -z "$line" ] || [ "${line#\#}" != "$line" ]) && continue
	  # Add each hostname entry with the $DOCKER_HOST_IP as mapping:
	  printf '%s\t%s\n' "$DOCKER_HOST_IP" "$line"
	done < "$1"
	echo "$marker_end"
}

get_hosts_content() {
	# Retrieve the current host settings:
	local hosts_content="$(cat /etc/hosts)"
	local file
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
	local hosts_content="$1"
	# Diff /etc/hosts with the new content:
	local hosts_diff="$(echo "$hosts_content" | diff /etc/hosts -)"
	if [ ! "$hosts_diff" ]; then
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
	local confirmation
	read confirmation
	if [ "$confirmation" = "y" ]; then
	  # Check if we have root access:
	  if [ $(id -u) -eq 0 ]; then
	    echo "$hosts_content" > /etc/hosts
	  else
	    # Get root access and then write the new hosts file:
	    echo "$hosts_content" | sudo tee /etc/hosts > /dev/null
	  fi
	  # Check if the last command failed:
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
