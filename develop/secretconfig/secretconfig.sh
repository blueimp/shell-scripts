#!/bin/sh

#
# Use environment variables to create file contents and replace placeholders.
# Usage: ./secretconfig.sh [config]
#
# The default configuration file is "/usr/local/etc/secretconfig.conf".
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

# Iterate over each line of the config file:
while read line
do
  # Skip empty lines:
  if [[ -z "$line" ]]
  then
    continue
  fi
  # Extract the substring up to the first space as variable name:
  local name=${line%% *}
  # Extract the rest of the string and trim any surrounding whitespace:
  local path=$(echo ${line#* })
  # Evaluate the name as environment variable:
  eval 'local value=$'$name
  # Print an error message for empty environment variables:
  if [[ -z "$value" ]]
  then
    echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) \$$name is empty." >&2
    continue
  fi
  # Check if file exists and has a size greater than zero:
  if [[ -s "$path" ]]
  then
    # Replace the placeholder with the content of the environment variable:
    awk -v find="{{$name}}" -v repl="$value" \
      's=index($0,find){$0=substr($0,1,s-1) repl substr($0,s+length(find))}1' \
      "$path" > "$path".tmp && mv "$path".tmp "$path"
  else
    # Create the path if it doesn't exist:
    mkdir -p "$(dirname "$path")"
    # Fill (or create) the file with the content of the environment variable:
    echo "$value" >> "$path"
  fi
# If no config file argument is given, use the the default config as input:
done < "${1:-/usr/local/etc/secretconfig.conf}"
