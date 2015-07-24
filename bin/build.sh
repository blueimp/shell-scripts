#!/bin/sh

#
# Builds the docker images of all folders in a given directory.
# If no directory is given, builds the images of the develop directory.
#
# Usage: ./build.sh [images_path]
#
# Copyright 2015, Sebastian Tschan
# https://blueimp.net
#
# Licensed under the MIT license:
# http://www.opensource.org/licenses/MIT
#

# Exit immediately if a command exits with a non-zero status:
set -e

# Change to the given or the default develop directory:
cd "${1:-$(dirname "$0")/../develop}"

# Normalizes according to docker hub project/tag naming conventions:
normalize() {
	echo "$1" | tr '[A-Z]' '[a-z]' | sed 's/[^a-z0-9._-]//g'
}

# Use the normalized project folder name:
PROJECT=$(normalize "$(basename "$PWD")")

# Iterate over all visible folders in the given directory:
for dir in $(ls -d */)
do
	# Build a docker image for each folder:
	docker build -t $PROJECT/$(normalize "$dir") "$dir"
done
