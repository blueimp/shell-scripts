#!/bin/sh

#
# Updates the docker images used in a given docker-compose YAML file.
#
# Usage: ./pull-docker-images.sh [-x exclude] [docker-compose.yml]
#
# Uses the docker-compose.yml file of the current directory by default.
# Prompts a docker login if no configuration has been saved yet.
# Allows to define a grep pattern to exclude images.
# By default, excludes images with organization prefixes less than 4 chars.
#
# Copyright 2015, Sebastian Tschan
# https://blueimp.net
#
# Licensed under the MIT license:
# http://www.opensource.org/licenses/MIT
#

if [ ! -f ~/.docker/config.json ]; then
	echo 'Login to Docker Hub:'
	docker login
fi

# Exclude images with organization prefixes less than 4 chars by default:
EXCLUDE='^.{1,3}/'
if [ "$1" = '-x' ]; then
  EXCLUDE="$2"
  shift 2
fi

echo # Newline for better readability

# Iterate over the docker image definitions in a given YAML file:
for image in $(
		# Extract lines containing an image definition:
		grep -w 'image:' "${1:-docker-compose.yml}" |
		# Extract the image definition:
		awk '{print $2}' |
		# Sort and remove duplicate entries:
		sort -u |
		# Ignore excluded images:
		grep -vE "$EXCLUDE"
	); do
	# Pull the latest image version from the docker hub:
	docker pull "$image"
	echo # Newline for better readability
done
