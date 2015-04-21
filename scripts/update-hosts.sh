#!/bin/bash

#
# Updates hostnames for $DOCKER_HOST_IP or 127.0.0.1 in /etc/hosts.
# Usage: ./update-hosts.sh [-f file] [hostname1] [hostname2] [...]
# 
# A config file with hostnames can be provided via -f option.
# The hostnames in the config file should be separated by newlines.
# 
# Copyright 2015, Sebastian Tschan
# https://blueimp.net
# 
# Licensed under the MIT license:
# http://www.opensource.org/licenses/MIT
#

if [ -z "$DOCKER_HOST_IP" ]
then
  DOCKER_HOST_IP="127.0.0.1"
fi

function print_usage() {
  echo "Usage: $0 [-f file] [hostname1] [hostname2] [...]" >&2
}

if [ "$1" = "-h" ] || [ "$1" = "--help" ]
then
  print_usage
  exit
fi

# Check if host entries are provided via config file:
if [ "$1" = "-f" ]
then
  if [[ -z "$2" ]]
  then
    print_usage
    exit 1
  fi
  # Add host entries from the config file as arguments:
  set -- "$@" $(cat "$2" | sed -e "s/[ \t\r\n\v\f]\+/ /g")
  shift 2
fi

DEVHOSTS=("$@")

MARKERSTART="## dev hosts start"
MARKEREND="## dev hosts end"

TMPFILE=$(mktemp /tmp/hosts.XXXXXXXXXX)

# Copy hosts to temporary file with old dev host entries removed:
sed "/$MARKERSTART/,/$MARKEREND/d" /etc/hosts > $TMPFILE

# Check if we have any dev hosts set:
if [ -n "$DEVHOSTS" ]
then
  # Add dev host entries with the $DOCKER_HOST_IP to the temporary file:
  echo "$MARKERSTART" >> $TMPFILE
  for HOSTNAME in "${DEVHOSTS[@]}"
  do
    echo -e "$DOCKER_HOST_IP\t$HOSTNAME" >> $TMPFILE
  done
  echo "$MARKEREND" >> $TMPFILE
fi

DIFF=$(diff /etc/hosts $TMPFILE)

CONTENT=$(cat $TMPFILE)

rm $TMPFILE

if [ "$DIFF" ]
then
  echo
  echo "$DIFF"
  echo
  echo "Update /etc/hosts with the given changes?"
  echo "This will require Administrator privileges."
  select yn in "Yes" "No"; do
    case $yn in
      Yes )
        echo "$CONTENT" | sudo tee /etc/hosts > /dev/null
        if [ $? -eq 0 ]
        then
          echo "Successfully updated /etc/hosts."
        else
          echo "Update of /etc/hosts failed."
        fi
        break
        ;;
      No )
        echo "No updates to /etc/hosts written."
        break
        ;;
    esac
  done
else
  echo "No updates to /etc/hosts required."
fi
