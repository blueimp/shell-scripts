#!/bin/sh

#
# Combines a given MP4 video file with a subtitles file in the same directory.
# The subtitles file must have the same file name, but with ".srt" extension.
#
# The language of the audio and subtitles track can be provided as optional
# second argument as ISO 639-2 language code (default is "eng").
#
# Usage: ./add-movie-subtitles.sh movie.mp4 [LANG]
#
# Requires FFmpeg to be installed.
#

set -e

NAME=${1%.*}
LANG=${2:-eng}

file_exists () {
  if [ ! -e "$1" ]; then
    echo "File not found: \"$1\"" >&2
    return 1
  fi
}

file_exists "$NAME".mp4
file_exists "$NAME".srt

ffmpeg \
  -i "$NAME".mp4 \
  -i "$NAME".srt \
  -c copy \
  -c:s mov_text \
  -metadata:s:s:0 language="$LANG" \
  -metadata:s:a:0 language="$LANG" \
  "$NAME [$LANG subtitles]".mp4
