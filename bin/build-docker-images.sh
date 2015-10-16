#!/bin/sh

#
# Builds images for each Dockerfile found recursively in the current directory.
# Alternatively builds only the Dockerfiles provided as command-line arguments.
# Also accepts directories containing a default Dockerfile as arguments.
#
# Usage: ./build-docker-images.sh [Dockerfile|directory] [...]
#
# Tags images based on git branch names, with "master" being tagged as "latest".
# Resolves image dependencies for images in the same project.
#
# Copyright 2015, Sebastian Tschan
# https://blueimp.net
#
# Licensed under the MIT license:
# http://www.opensource.org/licenses/MIT
#

# Normalizes according to docker hub project/tag naming conventions:
normalize() {
	echo "$1" | tr '[A-Z]' '[a-z]' | sed 's/[^a-z0-9._-]//g'
}

# Build and tag the image based on the git branches in the current directory:
build_versions() {
	local image="$1"
	if [ ! -d '.git' ]; then
		# Not a git repository, so simply build a "latest" image version:
		docker build -t "$image" .
		return $?
	fi
	current_branch=$(git rev-parse --abbrev-ref HEAD)
	# Iterate over all branches:
	local branches=$(git for-each-ref --format='%(refname:short)' refs/heads/)
	for branch in $branches; do
		git checkout $branch
		# Tag master as "latest":
		if [ "$branch" = 'master' ]; then
			branch='latest'
		fi
		# Build and tag the image with the branch name:
		docker build -t "$image:$branch" .
	done
	git checkout "$current_branch"
}

# Builds an image for each git branch of the given Dockerfile directory:
build() {
	local cwd="$PWD"
	if [ -f "$1" ]; then
		local file="$(basename "$1")"
		local dir="$(dirname "$1")"
	else
		# Use the default Dockerfile if the argument is a directory:
		local file='Dockerfile'
		local dir="$1"
		if [ ! -f "$dir/$file" ]; then
			echo "$dir/$file is not a valid file." >&2
			return 1
		fi
	fi
	cd "$dir"
	# Use the parent folder for the project name:
	local project="$(cd .. && normalize "$(basename "$PWD")")"
	# Use the current folder for the image name:
	local image="$project/$(normalize "$(basename "$PWD")")"
	# Check if the image depends on another image of the same project:
	local from=$(grep "^FROM $project/" "$file" | awk '{print $2}')
	# If it does, only build if the image is already available:
	if [ -z "$from" ] || docker inspect "$from" > /dev/null 2>&1; then
		build_versions $image
	else
		echo "$image requires $from ..." >&2 && false
	fi
	local status=$?
	cd "$cwd"
	return $status
}

# Builds and tags images for each Dockerfile in the arguments list:
build_images() {
	# Set the maximum number of calls on the first run:
	if [ $MAX_CALLS = 0 ]; then
		# Worst case scenario needs n*(n+1)/2 calls for dependency resolution,
		# which is the sum of all natural numbers (1+2+3+4+...n).
		# n is the number of arguments (=Dockerfiles) provided:
		MAX_CALLS=$(($#*($#+1)/2))
	fi
	CALLS=$(($CALLS+1))
	if [ $CALLS -gt $MAX_CALLS ]; then
		echo 'Could not resolve image dependencies.' >&2
		return 1
	fi
	for file; do
		# Shift the arguments list to remove the current Dockerfile:
		shift
		if ! build "$file"; then
			# The current build requires another image as dependency,
			# so we add it to the end of the build list and start over:
			build_images "$@" "$file"
			return $?
		fi
	done
}

MAX_CALLS=0
CALLS=0

build_images ${@:-$(find . -name Dockerfile)}
