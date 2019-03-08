#!/bin/sh

#
# Sets the modification times of the given files and the files in the given
# directories to their respective git commit timestamps.
#
# Usage: ./apply-commit-times.sh directory|file [...]
#
# Copyright 2017, Sebastian Tschan
# https://blueimp.net
#
# Licensed under the MIT license:
# https://opensource.org/licenses/MIT
#

set -e

# Set the timezone to UTC so `git log` and `touch` do not diverge:
export TZ=UTC0

apply_commit_time() {
  # Extract the commit date for the file in `touch -t` format (CCYYMMDDhhmm.ss):
  timestamp=$(git log -1 --format=%cd --date=format-local:%Y%m%d%H%M.%S -- "$1")
  if [ -n "$timestamp" ]; then
    # Set the modification time of the given file to the commit timestamp:
    touch -t "$timestamp" "$1"
  fi
}

# Check if the shell supports the "-d" option for the `read` built-in:
# shellcheck disable=SC2039
if printf '%s\0' 1 2 | read -r -d '' 2>/dev/null; then
  iterate() {
    # Disable the internal field separator (IFS) and iterate over the null byte
    # separated file paths using the "-d" option of the `read` built-in:
    while IFS= read -r -d '' FILE; do apply_commit_time "$FILE"; done
  }
else
  iterate() {
    # Transform the null byte separated files paths into command-line arguments
    # to the script itself via `xargs`.
    # The system-defined command-line arguments constraints will limit the
    # number of files that can be processed for a given directory, which should
    # be below the number defined via "-n" option for xargs:
    xargs -0 -n 100000 "$0"
  }
fi

while [ $# -gt 0 ]; do
  # Is the argument a directory path?
  if [ -d "$1" ]; then
    # The "-z" option of `git ls-tree` outputs null byte separated file paths:
    git ls-tree -r -z --name-only HEAD -- "$1" | iterate
  # Else is the argument a path to a readable file?
  elif [ -r "$1" ]; then
    apply_commit_time "$1"
  fi
  shift
done
