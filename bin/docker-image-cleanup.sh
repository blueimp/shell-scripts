#!/bin/sh
# shellcheck shell=dash

# Remove dangling docker images:
# shellcheck disable=SC2046
docker rmi $(docker images -f 'dangling=true' -q)
