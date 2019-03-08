#!/bin/bash

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

while [ $# -gt 0 ]; do
  # Is the argument a directory path?
  if [ -d "$1" ]; then
    # The "-z" option of `git ls-tree` outputs NUL byte separated file paths,
    # which can be iterated over with the "-d" option of the `read` built-in.
    # Since this option not available in POSIX shell, bash is required:
    git ls-tree -r -z --name-only HEAD -- "$1" | while IFS= read -d '' -r FILE
    do apply_commit_time "$FILE"; done
  # Else is the argument a path to a readable file?
  elif [ -r "$1" ]; then
    apply_commit_time "$1"
  fi
  shift
done
