#!/bin/sh

#
# Removes dangling docker images.
#
# Usage: ./cleanup-docker-images.sh
#
# Copyright 2015, Sebastian Tschan
# https://blueimp.net
#
# Licensed under the MIT license:
# http://www.opensource.org/licenses/MIT
#

# Remove dangling docker images:
docker rmi $(docker images -f 'dangling=true' -q)
