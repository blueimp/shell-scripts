#!/bin/sh
# shellcheck shell=dash

#
# Waits for the given host(s) to be available via TCP before executing a given
# command.
#
# Usage: ./wait.sh [-t timeout] host:port [host:port] [...] [-- command args...]
#
# It accepts a number of `host:port` combinations to connect to via netcat.
# The command to execute after each host is reachable can be supplied after the
# `--` argument.
# The default timeout of 10 seconds can be changed via `-t timeout` argument.
#
# Copyright 2016, Sebastian Tschan
# https://blueimp.net
#
# Licensed under the MIT license:
# https://opensource.org/licenses/MIT
#

set -e

TIMEOUT=10

is_integer() {
  test "$1" -eq "$1" 2> /dev/null
}

connect_to_service() {
  nc -w 1 -z "$1" "$2"
}

wait_for_service() {
  local host="${1%:*}"
  local port="${1#*:}"
  local output
  if ! is_integer "$port"; then
    printf 'Error: "%s" is not a valid host:port combination.\n' "$1" >&2
    return 1
  fi
  printf 'Waiting for %s to become available ... ' "$1" >&2
  # shellcheck disable=SC2155
  local timeout=$(($(date +%s)+TIMEOUT))
  while ! output="$(connect_to_service "$host" "$port" 2>&1)"; do
    if [ "$(date +%s)" -gt "$timeout" ]; then
      echo 'timeout' >&2
      if [ ! -z "$output" ]; then
        echo "$output" >&2
      fi
      return 1
    fi
    sleep 1
  done
  echo 'done' >&2
}

while [ $# != 0 ]; do
  if [ "$1" = '-t' ] || [ "$1" = '--timeout' ]; then
    if ! is_integer "$2"; then
      printf 'Error: "%s" is not a timeout integer.\n' "$2" >&2
      exit 1
    fi
    TIMEOUT="$2"
    shift 2
  fi
  if [ "$1" = '--' ]; then
    shift
    exec "$@"
  fi
  wait_for_service "$1"
  shift
done
