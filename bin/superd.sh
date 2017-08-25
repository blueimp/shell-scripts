#!/bin/sh
# shellcheck shell=dash

#
# Supervisor daemon to manage long running processes as a group.
# Terminates all remaining child processes as soon as one child exits.
# Written as entrypoint service for multi-process docker containers.
#
# Usage: ./superd.sh [config_file]
#
# The default superd configuration file is "/usr/local/etc/superd.conf".
# An alternate configuration file can be provided as first argument.
#
# Each line of the superd configuration file must have the following format:
# command [args...]
# Each command will be run by superd as a background process.
# If one command terminates, all commands will be terminated.
# Empty lines and lines starting with a hash (#) will be ignored.
#
# Copyright 2015, Sebastian Tschan
# https://blueimp.net
#
# Licensed under the MIT license:
# https://opensource.org/licenses/MIT
#

# The list of pids for the background processes:
PIDS=''

# Runs the given command in a background process and stores the pid:
run() {
  "$@" &
  PIDS="$PIDS $!"
}

# Runs commands defined in the given config file:
startup() {
  while read -r line; do
    # Skip empty lines and lines starting with a hash (#):
    [ -z "$line" ] || [ "${line#\#}" != "$line" ] && continue
    # Run the given command line:
  	# shellcheck disable=SC2086
    run $line
  # Use the given config file as input:
  done < "$1"
}

# Returns all given processes and their descendants tree as flat list:
collect() {
  local pid
  for pid in "$@"; do
    printf ' %s' "$pid"
  	# shellcheck disable=SC2046
    collect $(pgrep -P "$pid")
  done
}

# Terminates the given list of processes:
terminate() {
  local pid
  for pid in "$@"; do
    # Terminate the given process, ignore stdout and stderr output:
    kill "$pid" > /dev/null 2>&1
    # Wait for the process to stop:
    wait "$pid"
  done
}

# Initiates a shutdown by terminating the tree of child processes:
shutdown() {
  # shellcheck disable=SC2046
  terminate $(collect $(pgrep -P $$))
}

# Monitors the started background processes until one of them exits:
monitor() {
  local pid
  while true; do
    for pid in $PIDS; do
      # Return if the given process is not running:
      ! kill -s 0 "$pid" > /dev/null 2>&1 && return
    done
    sleep 1
  done
}

# Initiate a shutdown on SIGINT and SIGTERM:
trap 'shutdown; exit' INT TERM

# Start the commands defined in the given or the default config file:
startup "${1:-/usr/local/etc/superd.conf}" || exit $?

# Monitor the started background processes until one of them exits:
monitor

# Initiate a shutdown:
shutdown
