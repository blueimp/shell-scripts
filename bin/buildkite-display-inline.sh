#!/bin/sh

#
# Displays Buildkite artifacts inline. 
# Searches the given directory for files with the given extension.
# Displays images (jpg|jpeg|gif|png) inline and other files as links.
# Displays the inlines images/links in sorted order.
#
# See also:
# https://buildkite.com/docs/pipelines/links-and-images-in-log-output
#
# Usage: ./buildkite-display-inline.sh directory extension
# 
# Example: ./buildkite-display-inline.sh reports/screenshots png
#

set -e

inline_link() {
  LINK="url='$1'"
  if [ -n "$2" ]; then
    LINK="$LINK;content='$2'"
  fi
  printf '\033]1339;%s\a\n' "$LINK"
}

inline_image() {
  printf '\033]1338;url=%s;alt=%s\a\n' "$1" "$2"
}

DIR=$1
EXT=$2

if [ ! -d "$DIR" ]; then exit; fi

# If the current dir is not the git root, add a prefix to the artifact URLs:
GIT_ROOT=$(git rev-parse --show-toplevel)
if [ "$GIT_ROOT" != "$PWD" ]; then
  PREFIX=${PWD#$GIT_ROOT/}/
else
  PREFIX=
fi

# shellcheck disable=SC2039
find "$DIR" -name "*.$EXT" -print0 | sort -z | while IFS= read -r -d '' FILE; do
  TITLE=$(basename "$FILE" ".$EXT")
  inline_link "artifact://$PREFIX$FILE" "$TITLE"
  case "$EXT" in
    jpg|jpeg|gif|png) inline_image "artifact://$PREFIX$FILE" "$TITLE";;
  esac
done
