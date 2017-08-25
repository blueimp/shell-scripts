#!/bin/sh

#
# Creates a random string with characters from [A-Za-z0-9]
#
# Usage: ./random.sh length
#

LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | dd bs="${1?}" count=1 2>/dev/null
echo
