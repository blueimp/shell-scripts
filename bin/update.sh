#!/bin/sh

#
# Updates the docker images used in a given YAML file.
# Uses the docker-compose.yml file of the current directory by default.
#
# Usage: ./update.sh [docker-compose.yml]
#
# Copyright 2015, Sebastian Tschan
# https://blueimp.net
#
# Licensed under the MIT license:
# http://www.opensource.org/licenses/MIT
#

# Iterate over the docker image definitions in a given YAML file:
for image in $(
		# Extract lines containing an image definition:
		grep -w 'image:' ${1:-docker-compose.yml} |
		# Extract the image definition:
		awk '{print $2}' |
		# Sort and remove duplicate entries:
		sort -u |
		# Ignore development images:
		grep -v 'develop/'
	); do
	# Pull the latest image version from the docker hub:
	docker pull "$image"
done
