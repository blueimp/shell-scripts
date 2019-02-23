#!/bin/sh

#
# Starts the Android virtual device with a writeable filesystem.
# Starts the given AVD or by default the first in the AVD list.
# If a hosts file is provided as argument, replaces /etc/hosts on the device
# with the given file.
#
# Usage: ./android-emulator-hosts.sh [-avd AVD] [hosts-file]
#
# Copyright 2019, Sebastian Tschan
# https://blueimp.net
#
# Licensed under the MIT license:
# https://opensource.org/licenses/MIT
#

set -e

if [ -z "$ANDROID_HOME" ]; then
  echo 'Error: ANDROID_HOME is not defined.' >&2
  exit 1
fi

# shellcheck disable=SC2139
alias emulator="$ANDROID_HOME/emulator/emulator"
# shellcheck disable=SC2139
alias adb="$ANDROID_HOME/platform-tools/adb"

# Echos first AVD listed
avd() {
  emulator -list-avds | head -n 1
}

is_boot_completed() {
  test "$(adb shell getprop sys.boot_completed | tr -d '\r')" = 1
}

update_hosts_file() {
  echo 'Waiting for device to be ready ...'
  adb wait-for-device
  while ! is_boot_completed; do
    sleep 1
  done
  adb root
  adb remount
  adb push "$1" /etc/hosts
  adb unroot
}

shutdown() {
  kill "$PID"
}

# Initiate a shutdown on SIGINT and SIGTERM:
trap 'shutdown; exit' INT TERM

if [ "$1" = "-avd" ]; then
  AVD=$2
  shift 2
else
  AVD=$(avd)
fi

HOSTS_FILE=$1

if [ -n "$HOSTS_FILE" ]; then
  # Test for arguments beginning with a dash:
  if [ -z "${HOSTS_FILE%%-*}" ]; then
    echo 'Usage:' "$0" '[-avd AVD] [hosts-file]' >&2
    exit 1
  elif [ ! -r "$HOSTS_FILE" ]; then
    echo 'Not a readable file:' "$HOSTS_FILE" >&2
    exit 1
  fi
fi

emulator -avd "$AVD" -writable-system & PID=$!

if [ -n "$HOSTS_FILE" ]; then
  update_hosts_file "$HOSTS_FILE"
fi

wait "$PID"
