#!/bin/sh

#
# Global search and replace with variable arguments.
# Takes input from STDIN and prints to STDOUT.
# Supports multiline replacement strings.
#
# Usage: echo "$DATA" | ./replace.sh [-r] search_term replacement_string
#
# If the "-r" option is given, the search term is interpreted as
# POSIX Basic Regular Expression.
# Otherwise the search term is interpreted as literal string.
#
# Copyright 2015, Sebastian Tschan
# https://blueimp.net
#
# Licensed under the MIT license:
# https://opensource.org/licenses/MIT
#

# Global search and replace with the given pattern and replacement arguments:
gsub() {
  # In sed replacement strings, slash, backslash and ampersand must be escaped.
  # Multiline strings are allowed, but must escape newlines with a backslash.
  # Therefore, the last sed sub call adds a backslash to all but the last line:
  sed "s/$1/$(echo "$2" | sed 's/[/\&]/\\&/g;$!s/$/\\/g')/g"
}

# Global search and replace with the given search and replacement strings:
replace() {
  # In sed search patterns, the following characters have a special meaning:
  # The opening square bracket, slash, backslash, star and the dot.
  # Additionaly, the circumflex at the start and the dollar-sign at the end.
  # Therefore, we escape those characters in the given search string:
  gsub "$(echo "$1" | sed 's/[[/\*.]/\\&/g;s/^^/\\&/;s/$$/\\&/')" "$2"
}

if [ $# = 3 ] && [ "$1" = '-r' ]; then
  shift
  gsub "$@"
else
  replace "$@"
fi
