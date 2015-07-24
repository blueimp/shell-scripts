#!/bin/sh

#
# Print export statements based on output from commands in a config file.
# Escapes output for evaluation and supports multiline values.
#
# Usage: ./expenv.sh [config_file]
#
# The default configuration file is "$PWD/.expenv".
#
# Each line of the configuration file must have the following format:
# VARIABLE_NAME command [args...]
# Examples:
# PASSWORD echo secret
# KEY cat path/to/key_file
# Empty lines and lines starting with a hash (#) will be ignored.
#
# Copyright 2015, Sebastian Tschan
# https://blueimp.net
#
# Licensed under the MIT license:
# http://www.opensource.org/licenses/MIT
#

# Prints export statements based on command execution output:
# Usage: print_export VARIABLE_NAME command [args...]
# Examples:
# print_export PASSWORD echo secret
# print_export KEY cat path/to/key_file
print_export() {
  local name="$1"
  shift 1
  echo "export $name='$("$@" | sed "s/'/'\\\''/g")'"
}

# Parses the given config file and calls print_export for each line:
# Usage: print_exports_from_file config_file
print_exports_from_file() {
  # Enter the config file directory to account for relative config paths:
  cd "$(dirname "$1")"
  while read line; do
    # Skip empty lines and lines starting with a hash (#):
    ([ -z "$line" ] || [ "${line#\#}" != "$line" ]) && continue
    # Call print_export with the line components as arguments:
    eval "print_export $line"
  # Use the given config file as input:
  done < "$(basename "$1")"
}

# Use "$PWD/.expenv" as config file when called without argument:
print_exports_from_file "${1:-.expenv}"
