#!/bin/bash

#
# Wrapper script to write environment variables in config files.
# Replaces placeholders and creates files, then starts the given command.
#
# Usage: ./envconfig.sh [-f config] [command] [args...]
#
# The default configuration file is "/usr/local/etc/envconfig.conf".
# An alternate config file can be provided via -f option.
#
# Each line of the config file must have the following format:
# VARIABLE_NAME file_path
#
# Placeholders in configuration files must have the following format:
# {{VARIABLE_NAME}}
#
# Copyright 2015, Sebastian Tschan
# https://blueimp.net
#
# Licensed under the MIT license:
# http://www.opensource.org/licenses/MIT
#

# Exit immediately if a command exits with a non-zero status:
set -e

find_and_replace() {
  awk -v find="$1" -v repl="$2" \
    's=index($0,find){$0=substr($0,1,s-1) repl substr($0,s+length(find))}1' \
    "$3" > "$3".tmp && mv "$3".tmp "$3"
}

write_config() {
  while read line
  do
    # Skip empty lines:
    if [[ -z "$line" ]]
    then
      continue
    fi
    # Extract the substring up to the first space as variable name:
    local name=${line%% *}
    # Extract the remainder as path and trim any surrounding whitespace:
    local path=$(echo ${line#* })
    # Evaluate the name as environment variable, print error if unset:
    local value=$(eval 'echo "${'$name'?}"')
    # Check if the file exists and has a size greater than zero:
    if [[ -s "$path" ]]
    then
      # Replace the placeholder with the environment variable:
      find_and_replace "{{$name}}" "$value" "$path"
    else
      # Create the path if it doesn't exist:
      mkdir -p "$(dirname "$path")"
      # Set the environment variable as file content:
      echo "$value" >> "$path"
    fi
  # Use the given config file as input:
  done < "$1"
}

# Check if the config file is provided via command line:
if [ "$1" = "-f" ]
then
  # Use the given config file to write the env config:
  write_config "$2"
  # Remove the config file parameters from the arguments list:
  shift 2
else
  # Use the default config file to write the env config:
  write_config '/usr/local/etc/envconfig.conf'
fi

# Execute the given command (with the given arguments):
exec "$@"
