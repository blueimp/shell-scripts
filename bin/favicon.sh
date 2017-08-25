#!/bin/sh

#
# Creates a favicon for a given image.
#
# Usage: ./favicon.sh image_source [image_destination]
#
# Requires the ImageMagick convert binary to be installed.
#

convert \
  -density 384 \
  -colors 256 \
  -background transparent \
  -define icon:auto-resize=32,16 \
  "${1?}" \
  "${2:-favicon.ico}"
