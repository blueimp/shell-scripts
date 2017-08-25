#!/bin/sh

#
# Creates thumbnails for a directory of JPEG pictures.
#
# Usage: ./thumb.sh folder [size]
#
# Requires the ImageMagick convert binary to be installed.
#

set -e

cd "$1"
mkdir thumb

TARGET_SIZE=${2:-120}
SUBSAMPLE_SIZE=$((TARGET_SIZE*2))

for image in *.jpg; do
  convert \
    -define jpeg:size="${SUBSAMPLE_SIZE}x${SUBSAMPLE_SIZE}" "$image" \
    -thumbnail "${TARGET_SIZE}x${TARGET_SIZE}^" \
    -gravity center \
    -extent "${TARGET_SIZE}x${TARGET_SIZE}" \
    "thumb/$image"
done
