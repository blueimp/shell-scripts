#!/bin/sh

#
# Waits for the given hostname(s) to resolve to an IP before executing a given
# command.
# Resolves using `getent` (Linux/BSD) if available or `dscacheutil` (MacOS).
#
# Usage:
# ./wait-for-hostnames.sh [-q] [-t seconds] [hostname] [...] [-- cmd args...]
#
# The script accepts multiple hostnames as arguments or defined as
# WAIT_FOR_HOSTNAMES environment variable, separating the hostnames via spaces.
#
# The status output can be made quiet by adding the `-q` argument or by setting
# the environment variable WAIT_FOR_HOSTNAMES_QUIET to `1`.
#
# The default timeout of 10 seconds can be changed via `-t seconds` argument or
# by setting the WAIT_FOR_HOSTNAMES_TIMEOUT environment variable to the desired
# number of seconds.
#
# The command defined after the `--` argument separator will be executed if all
# the given hostnames can be resolved.
#
# Copyright 2019, Sebastian Tschan
# https://blueimp.net
#
# Licensed under the MIT license:
# https://opensource.org/licenses/MIT
#

set -e

if command -v getent > /dev/null 2>&1; then
  resolve_host() {
    getent hosts "$1"
  }
else
  resolve_host() {
    test -n "$(dscacheutil -q host -a name "$1")"
  }
fi

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

quiet_echo() {
  if [ "$QUIET" -ne 1 ]; then echo "$@" >&2; fi
}

wait_for_host() {
  HOST=$1
  if [ "$QUIET" -ne 1 ]; then
    printf "Waiting for hostname: %-${PADDING}s ... " "$1" >&2
  fi
  TIME_LIMIT=$(($(date +%s)+TIMEOUT))
  while ! OUTPUT="$(resolve_host "$HOST" 2>&1)"; do
    if [ "$(date +%s)" -ge "$TIME_LIMIT" ]; then
      quiet_echo timeout
      if [ -n "$OUTPUT" ]; then
        quiet_echo "$OUTPUT"
      fi
      return 1
    fi
    sleep 1
  done
  quiet_echo ok
}

set_padding() {
  PADDING=0
  while [ $# != 0 ]; do
    case "$1" in
      -t) shift 2;;
      -q) break;;
      --) break;;
       *) test ${#1} -gt $PADDING && PADDING=${#1}; shift;;
    esac
  done
}

QUIET=${WAIT_FOR_HOSTNAMES_QUIET:-0}
set_timeout "${WAIT_FOR_HOSTNAMES_TIMEOUT:-10}"

if [ "$QUIET" -ne 1 ]; then
  # shellcheck disable=SC2086
  set_padding $WAIT_FOR_HOSTNAMES "$@"
fi

while [ $# != 0 ]; do
  case "$1" in
    -t) set_timeout "$2"; shift 2;;
    -q) QUIET=1; shift;;
    --) shift; break;;
     *) wait_for_host "$1"; shift;;
  esac
done

for HOST in $WAIT_FOR_HOSTNAMES; do
  wait_for_host "$HOST"
done

exec "$@"
