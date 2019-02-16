#!/bin/sh

#
# Waits for the given host(s) to be available via TCP before executing a given
# command.
#
# Usage: ./wait.sh [-t timeout] [-q] host:port [...] [-- command args...]
#
# It accepts a number of `host:port` combinations to connect to via netcat.
# The command to execute after each host is reachable can be supplied after the
# `--` argument.
# The default timeout of 10 seconds can be changed via `-t timeout` argument.
# The status output can be made quiet via `-q argument.
#
# Copyright 2016, Sebastian Tschan
# https://blueimp.net
#
# Licensed under the MIT license:
# https://opensource.org/licenses/MIT
#

set -e

TIMEOUT=10
QUIET=0

is_integer() {
  test "$1" -eq "$1" 2> /dev/null
}

set_timeout() {
  if ! is_integer "$1"; then
    printf 'Error: "%s" is not a valid timeout value.\n' "$1" >&2
    return 1
  fi
  TIMEOUT="$1"
}

connect_to_service() {
  nc -w 1 -z "$1" "$2"
}

quiet_echo() {
  if [ "$QUIET" -ne 1 ]; then echo "$@" >&2; fi
}

wait_for_service() {
  HOST="${1%:*}"
  PORT="${1#*:}"
  if ! is_integer "$PORT"; then
    printf 'Error: "%s" is not a valid host:port combination.\n' "$1" >&2
    return 1
  fi
  if [ "$QUIET" -ne 1 ]; then
    printf 'Waiting for %s to become available ... ' "$1" >&2
  fi
  time=$(($(date +%s)+TIMEOUT))
  while ! OUTPUT="$(connect_to_service "$HOST" "$PORT" 2>&1)"; do
    if [ "$(date +%s)" -gt "$time" ]; then
      quiet_echo 'timeout'
      if [ -n "$OUTPUT" ]; then
        quiet_echo "$OUTPUT"
      fi
      return 1
    fi
    sleep 1
  done
  quiet_echo 'done'
}

while [ $# != 0 ]; do
  case "$1" in
    -t)
      set_timeout "$2"
      shift 2
      ;;
    -q)
      QUIET=1
      shift
      ;;
    --)
      shift
      exec "$@"
      ;;
    *)
      wait_for_service "$1"
      shift
      ;;
  esac
done
