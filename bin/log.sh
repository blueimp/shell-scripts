#!/bin/sh

#
# Executes the given command and logs the output.
# Adds a datetime and PID prefix in front of each output line.
# Also logs the effective user and given command line.
#
# Usage: ./log.sh command [args...]
#
# The location of the log output can be defined
# with the following environment variable:
# LOGFILE='/var/log/out.log'
#
# The error log can also be piped into a separate file
# defined by the following environment variable:
# ERRFILE='/var/log/err.log'
#
# The date output formatting can be defined
# with the following environment variable:
# DATECMD='date -u +%Y-%m-%dT%H:%M:%SZ'
#
# The PID printf format can be defined
# with the following environment variable:
# PIDFORM='(%05d)'
#
# Copyright 2015, Sebastian Tschan
# https://blueimp.net
#
# Licensed under the MIT license:
# https://opensource.org/licenses/MIT
#

# Define default values:
[ -z "$ERRFILE" ] && ERRFILE="$LOGFILE"
[ -z "$DATECMD" ] && DATECMD='date -u +%Y-%m-%dT%H:%M:%SZ'
[ -z "$PIDFORM" ] && PIDFORM='(%05d)'

# Combines the given arguments with a datetime and PID prefix:
format() {
  # shellcheck disable=SC2059
  echo "$($DATECMD) $(printf "$PIDFORM" $$) [$1] $2"
}

# Logs to stdout:
out_log() {
  format "$@"
}

# Logs to stderr:
err_log() {
  format "$@" >&2
}

# Logs to a file:
out_file_log() {
  format "$@" >> "$LOGFILE"
}

# Logs to the errors file:
err_file_log() {
  format "$@" >> "$ERRFILE"
}

# Returns the defined log output:
get_log() {
  printf %s "${1:-out}"
  if [ "$1" = 'err' ] && [ -n "$ERRFILE" ] || [ -n "$LOGFILE" ]; then
    printf _file
  fi
  printf _log
}

# Processes stdin and logs each line:
process() {
  log=$(get_log "$1")
  while read -r line; do
    $log "$1" "$line"
  done
}

# Returns a string with the quoted arguments:
quote() {
  args=
  for arg; do
    # Escape single quotes:
    arg="$(echo "$arg" | sed "s/'/'\\\\''/g")"
    case "$arg" in
      # Quote arguments containing characters not in the whitelist:
      *[!a-zA-Z0-9_-]*)
        args="$args'$arg' ";;
      *)
        args="$args$arg ";;
    esac
  done
  echo "$args"
}

# Log the effective user:
$(get_log) usr "$(whoami)"

# Log the command:
$(get_log) cmd "$(quote "$@")"

# Set line buffered mode if the stdbuf command is available:
if [ $# -gt 0 ] && command -v stdbuf > /dev/null 2>&1; then
  set -- stdbuf -oL -eL "$@"
fi

# Execute the command and log stdout and stderr:
{ "$@" 2>&3 | process out; } 3>&1 1>&2 | process err
