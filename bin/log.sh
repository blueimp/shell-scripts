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
  while read -r line; do
    log "$1" "$line"
  done
}

# Rebuild the command string with quoted arguments:
CMD=""
for arg in "$@"; do
  # Escape single quotes:
  arg="$(echo "$arg" | sed "s/'/'\\\''/g")"
  case "$arg" in
    # Quote arguments containing characters not in the whitelist:
    *[!a-zA-Z0-9_-]*)
      CMD="$CMD'$arg' ";;
    *)
      CMD="$CMD$arg ";;
  esac
done

# Log the command:
log cmd "$CMD"

# Set line buffered mode if the stdbuf command is available:
CMD="$(command -v stdbuf > /dev/null 2>&1 && echo 'stdbuf -oL -eL ')$CMD"

# Execute the command and log stdout and stderr:
{ eval "$CMD" 2>&3 | process out; } 3>&1 1>&2 | process err
