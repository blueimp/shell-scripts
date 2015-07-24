#!/bin/sh

#
# Print the container id for a given docker-compose service.
#
# Usage: ./cid.sh service [project]
#
# Copyright 2015, Sebastian Tschan
# https://blueimp.net
#
# Licensed under the MIT license:
# http://www.opensource.org/licenses/MIT
#

# Exit immediately if a command exits with a non-zero status:
set -e

# Prints the normalized name of the project folder as used by docker-compose:
project_name() {
  basename "$(cd "$(dirname "$0")/.." && pwd)" \
    | tr '[A-Z]' '[a-z]' | sed s/[^a-z0-9]//g
}

# Define the labels used for the docker-compose service:
project_filter=label=com.docker.compose.project="${2:-$(project_name)}"
service_filter=label=com.docker.compose.service="$1"

# Retrieve the container id matching the defined docker-compose labels:
id="$(docker ps -q -l -f "$project_filter" -f "$service_filter")"

# Print an error message when the service has not been created:
if [ -z "$id" ]; then
	c031='\033[0;31m' # red
	c0='\033[0m' # no color
	printf "${c031}ERROR:${c0} docker-compose service \"$1\" not created\n" >&2
	exit 1
fi

# Print the container id:
echo "$id"
