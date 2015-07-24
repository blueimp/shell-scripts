#!/bin/sh

#
# Wrapper script to write environment variables in config files.
# Replaces placeholders and creates files, then starts the given command.
#
# Usage: ./envconfig.sh [-e config_env] [-f config_file] [command] [args...]
#
# The default envconfig configuration file is "/usr/local/etc/envconfig.conf".
# An alternate configuration file can be provided via -f option.
# An environment variable with configuration can be provided via -e option.
# Mappings provided via environment variable will be written first.
#
# Each line of the configuration for envconfig must have the following format:
# VARIABLE_NAME /absolute/path/to/config/file
# Empty lines and lines starting with a hash (#) will be ignored.
# Multiple mappings of the same VARIABLE_NAME or path are possible.
#
# Placeholders in config files must have the following format:
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
  while read line; do
    # Skip empty lines and lines starting with a hash (#):
    ([ -z "$line" ] || [ "${line#\#}" != "$line" ]) && continue
    # Extract the substring up to the first space as variable name:
    local name="${line%% *}"
    # Extract the remainder as path and trim any surrounding whitespace:
    local path="$(echo ${line#* })"
    # Evaluate the name as environment variable, print error if unset:
    local value="$(eval 'echo "${'$name'?}"')"
    # Check if the file exists and has a size greater than zero:
    if [ -s "$path" ]; then
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

# Check if envconfig configuration is provided via environment variable:
if [ "$1" = "-e" ]; then
  # Write the environment variable to a temporary file, fail if unset:
  eval 'echo "${'$2'?}"' > /tmp/envconfig.conf
  # Use the temporary file to write the env config:
  write_config /tmp/envconfig.conf
  # Shift the arguments list to remove the given -e option:
  shift 2
fi

# Check if the config file is provided via command line:
if [ "$1" = "-f" ]; then
  # Use the given config file to write the env config:
  write_config "$2"
  # Shift the arguments list to remove the given -f option:
  shift 2
else
  # Use the default config file to write the env config:
  write_config '/usr/local/etc/envconfig.conf'
fi

# Execute the given command (with the given arguments):
exec "$@"
