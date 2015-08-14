#!/bin/sh

#
# Run mongorestore in a docker container.
# Usage: MONGODB_CONTAINER=CONTAINER_ID ./mongorestore.sh [ARGS...]
#
# Copyright 2015, Sebastian Tschan
# https://blueimp.net
#
# Licensed under the MIT license:
# http://www.opensource.org/licenses/MIT
#

# Exit immediately if a command exits with a non-zero status:
set -e

MONGODB_USER="${MONGODB_USER:-mongodb}"

if [ -z "$MONGODB_CONTAINER" ]; then
	echo "Usage: MONGODB_CONTAINER=CONTAINER_ID $0" >&2
	exit 1
fi

if [ "$1" = "--help" ] || [ "$1" = "--version" ]; then
	docker exec -u $MONGODB_USER $MONGODB_CONTAINER mongorestore "$@"
	exit $?
fi

TMPDIR="$(mktemp -d /tmp/mongodb-dump-XXXXXXXXXX)"

cleanup() {
	rm -rf "$TMPDIR"
}

# Clean up on exit:
trap "EXITCODE=$?; cleanup; exit $EXITCODE" TERM EXIT

HOSTDIR=""
RESET=""
COUNT=$#
INDEX=0

# Loop over the arguments list to rebuild it:
for arg; do
	if [ -z "$RESET" ]; then
		# Reset the arguments list at the start of the loop:
		set --
		RESET="true"
	fi
	INDEX=$(($INDEX+1))
	if [ $INDEX = $COUNT ] && [ -d "$arg" ]; then
		HOSTDIR="$arg"
		# Replace the dump source with the temp dir:
		arg="$TMPDIR"
	fi
	# Rebuild the arguments list with each iteration:
	set -- "$@" "$arg"
done

if [ -z "$HOSTDIR" ]; then
	# Use the default dump target as host dir:
	HOSTDIR="$PWD/dump"
	# Set the temp dir as dump source:
	set -- "$@" "$TMPDIR"
fi

cd "$HOSTDIR"

# Import the dump data into the running mongo container:
docker exec $MONGODB_CONTAINER mkdir -p "$TMPDIR"
docker cp . $MONGODB_CONTAINER:"$TMPDIR"
docker exec -u $MONGODB_USER $MONGODB_CONTAINER mongorestore "$@"
docker exec $MONGODB_CONTAINER rm -rf "$TMPDIR"
