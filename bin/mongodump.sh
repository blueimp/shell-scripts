#!/bin/bash

#
# Run mongodump in a docker container.
# Usage: MONGODB_CONTAINER=CONTAINER_ID ./mongodump.sh [ARGS...]
#
# Copyright 2015, Sebastian Tschan
# https://blueimp.net
#
# Licensed under the MIT license:
# http://www.opensource.org/licenses/MIT
#

# Exit immediately if a command exits with a non-zero status:
set -e

MONGODB_USER=${MONGODB_USER:-mongodb}

if [[ -z "$MONGODB_CONTAINER" ]]; then
	echo "Usage: MONGODB_CONTAINER=CONTAINER_ID $0" >&2
	exit 1
fi

if [ "$1" = "--help" ] || [ "$1" = "--version" ]; then
	docker exec -u $MONGODB_USER $MONGODB_CONTAINER mongodump $@ || exit 1
	exit
fi

TMPDIR=$(mktemp -d /tmp/mongodb-dump-XXXXXXXXXX)

function cleanup() {
	rm -rf "$TMPDIR"
}

# Clean up on exit:
trap "EXITCODE=$?; cleanup; exit $EXITCODE" SIGTERM EXIT

HOSTDIR=""

for ((i=1; i<=$#; i++)); do
	# Check if dump target is set:
	if [ "${!i}" = "--out" ]; then
		HOSTDIR=${@:i+1:1}
		# Replace host dir argument with temp dir:
		set -- "${@:1:i}" "$TMPDIR" "${@:i+2:$#}"
		break
	fi
done

if [[ -z "$HOSTDIR" ]]; then
	# Use default dump target as host dir:
	HOSTDIR="$PWD/dump"
	# Set dump target to temp dir:
	set -- "$@" --out "$TMPDIR"
fi

mkdir -p "$HOSTDIR"
cd "$HOSTDIR"

# Export dump data to host dir:
docker exec -u $MONGODB_USER $MONGODB_CONTAINER mongodump $@
docker exec -u $MONGODB_USER $MONGODB_CONTAINER test -d $TMPDIR || exit 0
docker cp $MONGODB_CONTAINER:"$TMPDIR" .
docker exec -u $MONGODB_USER $MONGODB_CONTAINER rm -rf "$TMPDIR"

# Move the dump data out of the temp dir:
BASENAME=$(basename $TMPDIR)
mv $BASENAME/* .
rmdir $BASENAME

exit 0
