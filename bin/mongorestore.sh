#!/bin/bash

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

if [[ -z "$MONGODB_CONTAINER" ]]
then
	echo "Usage: MONGODB_CONTAINER=CONTAINER_ID $0" >&2
	exit 1
fi

if [ "$1" = "--help" ] || [ "$1" = "--version" ]
then
	docker exec $MONGODB_CONTAINER mongorestore $@ || exit 1
	exit
fi

TMPDIR=$(mktemp -d /tmp/mongodb-dump-XXXXXXXXXX)

function cleanup() {
	rm -rf "$TMPDIR"
}

# Clean up on exit:
trap "EXITCODE=$?; cleanup; exit $EXITCODE" SIGTERM EXIT

HOSTDIR="${@: -1}"

if [ -d "$HOSTDIR" ]
then
	# Keep all but the last argument:
	ARGS="${@:1:$#-1}"
else
	# Use default dump target as host dir:
	HOSTDIR="$PWD/dump"
	# Keep all arguments:
	ARGS="$@"
fi

cd "$HOSTDIR"

docker exec $MONGODB_CONTAINER mkdir -p "$TMPDIR"

# Set host dir argument to temp dir:
set -- "$ARGS" "$TMPDIR"

# Combine host dir contents into tar file:
DUMPFILE="$TMPDIR.tar.gz"
tar -cf "$DUMPFILE" .

# Import dump data into the running mongo container:
docker exec -i $MONGODB_CONTAINER sh -c "cat > '$DUMPFILE'" < "$DUMPFILE"
docker exec $MONGODB_CONTAINER tar -xf "$DUMPFILE" -C "$TMPDIR"
docker exec $MONGODB_CONTAINER mongorestore $@
docker exec $MONGODB_CONTAINER rm "$DUMPFILE"
docker exec $MONGODB_CONTAINER rm -rf "$TMPDIR"

rm "$DUMPFILE"

exit 0
