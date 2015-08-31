#!/bin/sh

#
# Updates hostnames for $DOCKER_HOST_IP or 127.0.0.1 in /etc/hosts.
# Usage: ./hostnames.sh [config_file]
#
# The default configuration file is "$PWD/hostnames".
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

# Normalizes according to docker-compose project naming rules:
normalize() {
	echo "$1" | tr '[A-Z]' '[a-z]' | sed s/[^a-z0-9]//g
}

if [ -z "$DOCKER_HOST_IP" ]; then
  DOCKER_HOST_IP='127.0.0.1'
fi

# Use the config file folder as project name:
PROJECT=$(normalize "$(basename "$(cd "$(dirname "${1:-.}")" && pwd)")")

MARKERSTART="## $PROJECT hosts start"
MARKEREND="## $PROJECT hosts end"

TMPFILE=$(mktemp /tmp/hosts.XXXXXXXXXX)

# Copy /etc/hosts to a temporary file with the old dev host entries removed:
sed "/$MARKERSTART/,/$MARKEREND/d" /etc/hosts > $TMPFILE

# Add the new dev host entries to the temporary file:
echo "$MARKERSTART" >> $TMPFILE
while read line; do
  # Skip empty lines and lines starting with a hash (#):
  ([ -z "$line" ] || [ "${line#\#}" != "$line" ]) && continue
  # Add each hostname entry with the $DOCKER_HOST_IP to the temporary file:
  printf '%s\t%s\n' "$DOCKER_HOST_IP" "$line" >> $TMPFILE
# Use "$PWD/hostnames" as config file when called without argument:
done < "${1:-hostnames}"
echo "$MARKEREND" >> $TMPFILE

# Diff the original hosts file with the temporary file:
DIFF="$(diff /etc/hosts $TMPFILE)"

# Store the content of the temporary file so we can delete it:
CONTENT="$(cat $TMPFILE)"
rm $TMPFILE

if [ ! "$DIFF" ]; then
  echo 'No updates to /etc/hosts required.'
  exit
fi

# Show a confirmation prompt to the user:
echo
echo "$DIFF"
echo
echo 'Update /etc/hosts with the given changes?'
echo 'This will require Administrator privileges.'
echo 'Please type "y" if you wish to proceed.'
read CONFIRM

if [ "$CONFIRM" = "y" ]; then
  # Check if we have root access:
  if [ $(id -u) -eq 0 ]; then
    echo "$CONTENT" > /etc/hosts
  else
    # Get root access and then write the new hosts file:
    echo "$CONTENT" | sudo tee /etc/hosts > /dev/null
  fi
  # Check if the last command failed:
  if [ $? -eq 0 ]; then
    echo "Successfully updated /etc/hosts."
    exit
  else
    echo "Update of /etc/hosts failed." >&2
    exit 1
  fi
fi

echo "No updates to /etc/hosts written."
