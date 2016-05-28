#!/bin/sh

# Remove dangling docker images:
docker rmi $(docker images -f 'dangling=true' -q)
