#!/bin/sh

#
# Executes the given command and logs the output.
# Adds a datetime prefix in front of each output line.
#
# Usage: ./log.sh command [args...]
#
# The location of the log output can be defined
# with the following environment variable:
# LOGFILE="/dev/stdout"
#
# The date output formatting can be defined
# with the following environment variable:
# DATECMD="date -u +%Y-%m-%dT%H:%M:%SZ"
#
# Copyright 2015, Sebastian Tschan
# https://blueimp.net
#
# Licensed under the MIT license:
# http://www.opensource.org/licenses/MIT
#

# Define default values:
[ -z "$LOGFILE" ] && LOGFILE=/dev/stdout
[ -z "$DATECMD" ] && DATECMD='date -u +%Y-%m-%dT%H:%M:%SZ'

# Adds the given arguments with a datetime prefix to the logfile:
log() {
  echo "$($DATECMD) [$1] $2" >> $LOGFILE
}

# Processes stdin and logs each line:
process() {
  while read -r; do
    log "$1" "$REPLY"
  done
}

# Rebuild the command string with quoted arguments:
CMD=""
for ARG in "$@"; do
  # Escape single quotes:
  ARG="$(echo "$ARG" | sed "s/'/'\\\''/g")"
  case "$ARG" in
    # Quote arguments containing characters not in the whitelist:
    *[^a-zA-Z0-9_-]*)
      CMD="$CMD'$ARG' ";;
    *)
      CMD="$CMD$ARG ";;
  esac
done

# Log the command:
log cmd "$CMD"

# Execute the command and log stdout and stderr:
{ eval "$CMD" 2>&3 | process out; } 3>&1 1>&2 | process err
