#!/bin/sh
# shellcheck shell=dash

#
# Run mongodump in a docker container.
# Usage: MONGODB_CONTAINER=CONTAINER_ID ./mongodump.sh [ARGS...]
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
	docker exec -u "$MONGODB_USER" "$MONGODB_CONTAINER" mongodump "$@"
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
LAST_ARG=""

# Loop over the arguments to adjust the dump target:
for arg; do
	if [ -z "$RESET" ]; then
		# Reset the arguments list at the start of the loop:
		set --
		RESET="true"
	fi
	# Check for a dump target in "--out=dump/" format:
	if [ "${arg#--out=}" != "$arg" ]; then
		arg="${arg#--out=}"
		set -- "$@" -o
		LAST_ARG="-o"
	fi
	# Check for a dump target in "-o dump/" or  "--out dump/" format:
	if [ "$LAST_ARG" = "-o" ] || [ "$LAST_ARG" = "--out" ]; then
		HOSTDIR="$arg"
		# Set the temp dir as new dump target:
		set -- "$@" "$TMP_DIR"
		LAST_ARG=""
		continue
	fi
	# Rebuild the arguments list with each iteration:
	set -- "$@" "$arg"
	LAST_ARG="$arg"
done

if [ -z "$HOSTDIR" ]; then
	# Use default dump target as host dir:
	HOSTDIR="$PWD/dump"
	# Set dump target to temp dir:
	set -- "$@" -o "$TMP_DIR"
fi

mkdir -p "$HOSTDIR"
cd "$HOSTDIR"

# Export dump data from the running mongodb container to the host dir
# and replace the temp dir with the host dir in the stderr output:
{ docker exec -u "$MONGODB_USER" "$MONGODB_CONTAINER" mongodump "$@" 2>&3; \
	} 3>&1 1>&2 | replace "$TMP_DIR" "$HOSTDIR" 1>&2
docker exec "$MONGODB_CONTAINER" test -d "$TMP_DIR" || exit 0
docker cp "$MONGODB_CONTAINER":"$TMP_DIR" .
docker exec "$MONGODB_CONTAINER" rm -rf "$TMP_DIR"

# Move the dump data out of the temp dir basename:
BASENAME="$(basename "$TMP_DIR")"
cp -r "$BASENAME"/* .
rm -rf "$BASENAME"

clean_exit
