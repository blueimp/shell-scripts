#!/bin/sh

#
# Executes a given command for each STDIN line in parallel.
# The command is called with the given arguments and the current line.
# The output of each command is printed in a separate section.
# Empty lines and lines starting with a hash (#) are skipped.
#
# Usage: echo "$DATA" | ./parallelize.sh [-q] [-s] [-f format] command [args...]
#
# Quite mode (-q) prints only command output.
# Sequential mode (-s) runs the commands sequentially instead of in parallel.
# A printf format string (-f format) can be defined to format the line before
# passing it on as argument to the command.
#
# Copyright 2016, Sebastian Tschan
# https://blueimp.net
#
# Licensed under the MIT license:
# https://opensource.org/licenses/MIT
#

set -e

# Color codes:
c031='\033[0;31m' # red
c032='\033[0;32m' # green
c036='\033[0;36m' # cyan
c0='\033[0m' # no color

# Prints the given error message and exits:
error_exit() {
  echo "${c031}$1${c0}" >&2
  echo "Usage: $0 [-e script] [-q] [-s] command [args...]" >&2
  exit 1
}

# Deletes the temp dir including the output files:
cleanup() {
  rm -rf "$TMP_DIR"
}

# Prints output unless in quiet mode:
prints() {
  if [ -z "$QUIET_MODE" ]; then echo "$@"; fi
}

# Formatted output unless in quiet mode:
printfs() {
  # shellcheck disable=SC2059
  if [ -z "$QUIET_MODE" ]; then printf "$@"; fi
}

# Returns the length of the longest line in this parallel execution:
max_line_length() {
  cat "$TMP_DIR/max_line_length"
}

# Execute the given command in parallel:
execute_parallel() {
  # Filter out empty lines and lines starting with a hash (#):
  if [ -z "$LINE" ] || [ "${LINE#\#}" != "$LINE" ]; then return; fi
  INDEX=$((INDEX+1))
  LINE_LENGTH=${#LINE}
  # Store the LINE in a file:
  LINE_PATH="$TMP_DIR/$(printf '%03d' "$INDEX")"
  echo "$LINE" > "$LINE_PATH"
  if [ "$LINE_LENGTH" -gt "$MAX_LINE_LENGTH" ]; then
    MAX_LINE_LENGTH=$LINE_LENGTH
    echo "$MAX_LINE_LENGTH" > "$TMP_DIR/max_line_length"
  fi
  # Run each command in parallel and store the output in a temp file:
  # shellcheck disable=SC2059
  if "$@" "$(printf "${FORMAT:-%s}" "$LINE")" > "$LINE_PATH".out 2>&1; then
    printfs "${c036}%-$(max_line_length)s${c0} ${c032}done${c0}\n" "$LINE"
  else
    printfs "${c036}%-$(max_line_length)s${c0} ${c031}failed${c0}\n" "$LINE"
  fi &
}

# Executes the given command sequentially:
execute_sequential() {
  # Filter out empty lines and lines starting with a hash (#):
  if [ -z "$LINE" ] || [ "${LINE#\#}" != "$LINE" ]; then return; fi
  prints
  prints "${c036}$LINE${c0}"
  prints '===================='
  # Run each command sequentially:
  # shellcheck disable=SC2059
  "$@" "$(printf "${FORMAT:-%s}" "$LINE")"
  prints '===================='
}

# Iterate over the lines from STDIN and executes the given command for each:
read_lines() {
  while read -r LINE; do
    "$@"
  done
}

QUIET_MODE=
SEQUENTIAL_MODE=
FORMAT=
INDEX=0
MAX_LINE_LENGTH=0

# Parse command-line options:
while getopts ':qsf:' opt; do
  case "$opt" in
   q) QUIET_MODE=true;;
   s) SEQUENTIAL_MODE='true';;
   f) FORMAT=$OPTARG;;
  \?) error_exit "Invalid option: -$OPTARG";;
   :) error_exit "Option -$OPTARG requires an argument.";;
  esac
done

# Remove the parsed options from the command-line arguments:
shift $((OPTIND-1))

if [ $# = 0 ]; then
  error_exit 'Missing command argument.'
fi

if [ -n "$SEQUENTIAL_MODE" ]; then
  read_lines execute_sequential "$@"
  prints
  exit
fi

# Create a temp dir for output files:
TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}"/"$(basename "$0")"-XXXXXXXXXX)

# Clean up after terminating child processes on SIGINT and SIGTERM:
trap 'wait;cleanup' INT TERM

prints
prints 'Please wait ...'

read_lines execute_parallel "$@"

# Wait for all child processes to terminate:
wait

# Print the content of the output files
for FILE in "$TMP_DIR"/*.out; do
  # If no files are found, the unexpanded pattern is returned as result:
  [ "$FILE" = "$TMP_DIR/*.out" ] && break
  prints
  # The line is stored in a file without ".out" extension:
  prints "# ${c036}$(cat "${FILE%\.out}")${c0}"
  prints '===================='
  cat "$FILE"
  prints '===================='
done

prints

cleanup
