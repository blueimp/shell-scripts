#!/bin/sh
# shellcheck shell=dash

#
# Run mongorestore in a docker container.
# Usage: MONGODB_CONTAINER=CONTAINER_ID ./mongorestore.sh [ARGS...]
#
# Copyright 2015, Sebastian Tschan
# https://blueimp.net
#
# Licensed under the MIT license:
# https://opensource.org/licenses/MIT
#

# Exit immediately if a command exits with a non-zero status:
set -e

MONGODB_USER="${MONGODB_USER:-mongodb}"

if [ -z "$MONGODB_CONTAINER" ]; then
	echo "Usage: MONGODB_CONTAINER=CONTAINER_ID $0" >&2
	exit 1
fi

if [ "$1" = "--help" ] || [ "$1" = "--version" ]; then
	docker exec -u "$MONGODB_USER" "$MONGODB_CONTAINER" mongorestore "$@"
	exit $?
fi

TMP_DIR="$(mktemp -d /tmp/mongodb-dump-XXXXXXXXXX)"

SCRIPTDIR="$(cd "$(dirname "$0")" && pwd)"

replace() {
	if [ -f "$SCRIPTDIR"/replace.sh ]; then
		"$SCRIPTDIR"/replace.sh "$@"
	else
		cat
	fi
}

clean_exit() {
	local status=$?
	rm -rf "$TMP_DIR"
	exit $status
}

# Clean up on exit:
trap 'clean_exit' INT TERM

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
	INDEX=$((INDEX+1))
	if [ "$INDEX" = "$COUNT" ] && [ -d "$arg" ]; then
		HOSTDIR="$arg"
		# Replace the dump source with the temp dir:
		arg="$TMP_DIR"
	fi
	# Rebuild the arguments list with each iteration:
	set -- "$@" "$arg"
done

if [ -z "$HOSTDIR" ]; then
	# Use the default dump target as host dir:
	HOSTDIR="$PWD/dump"
	# Set the temp dir as dump source:
	set -- "$@" "$TMP_DIR"
fi

cd "$HOSTDIR"

# Import the dump data into the running mongodb container:
docker exec "$MONGODB_CONTAINER" mkdir -p "$TMP_DIR"
docker cp . "$MONGODB_CONTAINER":"$TMP_DIR"
# Restore the imported dump data
# and replace the temp dir with the host dir in the stderr output:
{ docker exec -u "$MONGODB_USER" "$MONGODB_CONTAINER" mongorestore "$@" 2>&3; \
	} 3>&1 1>&2 | replace "$TMP_DIR" "$HOSTDIR" 1>&2
docker exec "$MONGODB_CONTAINER" rm -rf "$TMP_DIR"

clean_exit
