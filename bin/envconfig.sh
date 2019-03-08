#!/bin/sh

#
# Wrapper script to write environment variables in config files.
# Replaces placeholders and creates files, then starts the given command.
# Supports multiline variables, reading from file paths and base64 encoded data.
#
# Usage: ./envconfig.sh [-f config_file] [command] [args...]
#
# The default envconfig configuration file is "/usr/local/etc/envconfig.conf".
# An alternate configuration file can be provided via -f option.
# To read the configuration from STDIN, the placeholder "-" can be used.
#
# Each line of the configuration for envconfig must have the following format:
# VARIABLE_NAME /absolute/path/to/config/file
#
# Each mapped variable will be unset before the command given to envconfig is
# run, unless the variable name is prefixed with an exclamation mark:
# !VARIABLE_NAME /absolute/path/to/config/file
#
# Empty lines and lines starting with a hash (#) will be ignored.
# Multiple mappings of the same VARIABLE_NAME or path are possible.
#
# Placeholders in config files must have the following format:
# {{VARIABLE_NAME}}
#
# Variable content can be provided from a file location, given the following:
# The file path must be provided in a variable with "_FILE" suffix.
# The file contents will then be used for the variable without the prefix.
# For example, the contents of a file at $DATA_FILE will be used as $DATA.
#
# Variable content can be provided in base64 encoded form, given the following:
# The base64 data must be provided in a variable with "B64_" prefix.
# The decoded data will then be used for the variable without the prefix.
# For example, the content of $B64_DATA will be decoded and used as $DATA.
#
# Copyright 2015, Sebastian Tschan
# https://blueimp.net
#
# Licensed under the MIT license:
# https://opensource.org/licenses/MIT
#

set -e

# Returns the platform dependent base64 decode argument:
b64_decode_arg() {
  if [ "$(echo 'eA==' | base64 -d 2> /dev/null)" = 'x' ]; then
    printf %s -d
  else
    printf %s --decode
  fi
}

# Interpolates the given variable name:
interpolate() {
  if [ "$1" = '_' ] || ! expr "$1" : '[a-zA-Z_][a-zA-Z0-9_]*' 1>/dev/null; then
    echo "Invalid variable name: $1" >&2 && return 1
  fi
  # Check if a variable with the given name plus "_FILE" suffix exists:
  if eval 'test ! -z "${'"$1"'_FILE+x}"'; then
    # Read the contents from the interpolated file path:
    eval 'cat "${'"$1"'_FILE}"'
  # Check if a variable with the given name plus "B64_" prefix exists:
  elif eval 'test ! -z "${B64_'"$1"'+x}"'; then
    # Return the decoded content of the "B64_" prefixed variable:
    eval 'echo "$B64_'"$1"'"' | tr -d '\n' | base64 "$B64_DECODE_ARG"
  else
    # Interpolate the name as environment variable, print to stderr if unset:
    eval 'printf "%s" "${'"$1"'?}"'
  fi
}

# Global search and replace with the given pattern and replacement arguments:
gsub() {
  # In sed replacement strings, slash, backslash and ampersand must be escaped.
  # Multiline strings are allowed, but must escape newlines with a backslash.
  # Therefore, the last sed sub call adds a backslash to all but the last line:
  sed "s/$1/$(echo "$2" | sed 's/[/\&]/\\&/g;$!s/$/\\/g')/g"
}

# Parses the given config file and writes the env config:
write_envconfig() {
  # Store variables to unset in a space-separated list:
  unset_variables=
  # Set the platform dependent base64 decode argument:
  B64_DECODE_ARG="$(b64_decode_arg)"
  # Iterate over each line of the config file:
  while read -r line; do
    # Skip empty lines and lines starting with a hash (#):
    [ -z "$line" ] || [ "${line#\#}" != "$line" ] && continue
    # Extract the substring up to the first space as variable name:
    name="${line%% *}"
    # Check if the variable should be unset (no exclamation mark prefix):
    if [ "${name#!}" = "$name" ]; then
      # Store the name and its variants in the list of variables to unset:
      unset_variables="$unset_variables $name ${name}_FILE B64_$name"
    else
      # Remove the exclamation mark prefix:
      name="${name#!}"
    fi
    # Extract the substring after the last space as file path:
    path="${line##* }"
    # Check if the file exists and has a size greater than zero:
    if [ -s "$path" ]; then
      tmpfile="$(mktemp "${TMPDIR:-/tmp}/$name.XXXXXXXXXX")"
      # Replace the placeholder with the environment variable:
      gsub "{{$name}}" "$(interpolate "$name")" < "$path" > "$tmpfile"
      # Override the original file without changing permissions or ownership:
      cat "$tmpfile" > "$path" && rm "$tmpfile"
    else
      # Create the path if it doesn't exist:
      mkdir -p "$(dirname "$path")"
      # Set the environment variable as file content:
      interpolate "$name" >> "$path"
    fi
  # Use the given config file as input:
  done < "$1"
  # Unset the given variables:
  # shellcheck disable=SC2086
  unset $unset_variables
}

# Write the environment config using the provided configuration file:
if [ "$1" = "-f" ]; then
  if [ "$2" = - ]; then
    write_envconfig /dev/stdin
  else
    write_envconfig "$2"
  fi
  shift 2
else
  # Use the default config file to write the env config:
  write_envconfig '/usr/local/etc/envconfig.conf'
fi

# Execute the given command (with the given arguments):
exec "$@"
