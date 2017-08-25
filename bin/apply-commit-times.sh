#!/bin/bash

#
# Sets the modification time of all files in the given directory to their
# respective git commit timestamps.
#
# Usage: ./apply-commit-times.sh [directory]
#
# Copyright 2017, Sebastian Tschan
# https://blueimp.net
#
# Licensed under the MIT license:
# https://opensource.org/licenses/MIT
#

set -e

# Set the timezone to UTC+0 (used by `git show` via `strftime` and `touch`):
export TZ=UTC0

apply_commit_time() {
  # Retrieve the latest commit ID for the given file:
  local commit
  commit="$(git rev-list -1 HEAD "$1")"
  # Extract the commit author date in `touch -t` format (CCYYMMDDhhmm.ss):
  local timestamp
  timestamp=$(
    git show --pretty=format:%ad --date=format-local:%Y%m%d%H%M.%S "$commit" |
    head -n 1
  )
  # Set the modification time of the given file to the commit timestamp:
  touch -t "$timestamp" "$1"
}

# The "-z" option of `git ls-tree` outputs NUL byte separated file paths, which
# can be iterated over with the "-d" option of the `read` built-in, which is
# not available in POSIX shell. However, this allows us to handle any file name
# which is valid on UNIX systems:
git ls-tree -r -z --name-only HEAD -- "${1:-.}" | while IFS= read -d '' -r FILE
do
  if [ -r "$FILE" ]; then
    apply_commit_time "$FILE"
  fi
done
