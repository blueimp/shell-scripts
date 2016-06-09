#!/bin/sh
# shellcheck shell=dash

#
# Removes dangling docker images.
#
# Usage: ./docker-image-cleanup.sh
#

# Remove dangling docker images:
# shellcheck disable=SC2046
docker rmi $(docker images -f 'dangling=true' -q)
