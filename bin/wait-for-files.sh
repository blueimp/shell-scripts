#!/bin/sh

#
# Waits for the given file(s) to exist before executing a given command.
# Tests for existance by using `test -e`, which also allows to test for
# directories in addition to files.
#
# Usage:
# ./wait-for-files.sh [-q] [-t seconds] [file] [...] [-- command args...]
#
# The script accepts multiple files as arguments or defined as WAIT_FOR_FILES
# environment variable, separating the file paths via colons.
#
# The status output can be made quiet by adding the `-q` argument or by setting
# the environment variable WAIT_FOR_FILES_QUIET to `1`.
#
# The default timeout of 10 seconds can be changed via `-t seconds` argument or
# by setting the WAIT_FOR_FILES_TIMEOUT environment variable to the desired
# number of seconds.
#
# The command defined after the `--` argument separator will be executed if all
# the given files exist.
#
# Copyright 2019, Sebastian Tschan
# https://blueimp.net
#
# Licensed under the MIT license:
# https://opensource.org/licenses/MIT
#

set -e

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

wait_for_file() {
  FILE=$1
  if [ "$QUIET" -ne 1 ]; then
    printf "Waiting for file: %-${PADDING}s ... " "$1" >&2
  fi
  TIME_LIMIT=$(($(date +%s)+TIMEOUT))
  while ! test -e "$FILE"; do
    if [ "$(date +%s)" -ge "$TIME_LIMIT" ]; then
      quiet_echo timeout
      return 1
    fi
    sleep 1
  done
  quiet_echo ok
}

wait_for_files() {
  if [ -z "$1" ]; then
    return
  fi
  ORIGINAL_IFS=$IFS
  IFS=:
  # shellcheck disable=SC2086
  set -- $1
  IFS=$ORIGINAL_IFS
  for FILE; do
    wait_for_file "$FILE"
  done
}

set_padding() {
  PADDING=0
  ORIGINAL_IFS=$IFS
  IFS=:
  # shellcheck disable=SC2086
  set -- $WAIT_FOR_FILES "$@"
  IFS=$ORIGINAL_IFS
  while [ $# != 0 ]; do
    case "$1" in
      -t) shift 2;;
      -q) break;;
      --) break;;
       *) test ${#1} -gt $PADDING && PADDING=${#1}; shift;;
    esac
  done
}

QUIET=${WAIT_FOR_FILES_QUIET:-0}
set_timeout "${WAIT_FOR_FILES_TIMEOUT:-10}"

if [ "$QUIET" -ne 1 ]; then
  set_padding "$@"
fi

while [ $# != 0 ]; do
  case "$1" in
    -t) set_timeout "$2"; shift 2;;
    -q) QUIET=1; shift;;
    --) shift; break;;
     *) wait_for_file "$1"; shift;;
  esac
done

wait_for_files "$WAIT_FOR_FILES"

exec "$@"
