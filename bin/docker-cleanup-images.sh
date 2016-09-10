#!/bin/sh
# shellcheck shell=dash

#
# Removes dangling docker images.
#
# Usage: ./docker-cleanup-images.sh
#

# shellcheck disable=SC2046
docker rmi $(docker images -f 'dangling=true' -q)
