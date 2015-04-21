#!/bin/bash

#
# Export docker container IDs for labeled services as ENV constants.
# Usage: eval $(./export-container-ids.sh [-l label] service1 [service2] [...])
# 
# Copyright 2015, Sebastian Tschan
# https://blueimp.net
# 
# Licensed under the MIT license:
# http://www.opensource.org/licenses/MIT
#

LABEL="test.dev.service"

function print_usage() {
	echo "Usage: eval \$($0 [-l label] service1 [service2] [...])" >&2
}

# Allow overriding the default label:
if [ "$1" = "-l" ]
then
	if [[ -z "$2" ]]
	then
		print_usage
		exit 1
	fi
	LABEL="$2"
	shift 2
fi

if [[ -z "$1" ]]
then
	print_usage
	exit 1
fi

for SERVICE in "$@"
do
	# Define ENV constants in the form SERVICE_CONTAINER:
	VAR=$(echo "$SERVICE" | tr '[:lower:]' '[:upper:]')_CONTAINER

	# Retrieve the container id via docker ps:
	ID=$(docker ps -qlf "label=$LABEL=$SERVICE")

	if [[ -z "$ID" ]]
	then
		echo "No container with label '$LABEL=$SERVICE' found." >&2
	else
		# Echo the export command for the container id constant:
		echo "export $VAR='$ID';"
	fi
done
