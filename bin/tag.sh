#!/bin/sh

#
# Tags docker images of all folders in a directory based on git branch names.
# If no directory is given, tags the images of the develop directory.
#
# Usage: ./tag.sh [images_path]
#
# Copyright 2015, Sebastian Tschan
# https://blueimp.net
#
# Licensed under the MIT license:
# http://www.opensource.org/licenses/MIT
#

# Exit immediately if a command exits with a non-zero status:
set -e

# Change to the given or the default develop directory:
cd "${1:-$(dirname "$0")/../develop}"

# Normalizes according to docker hub project/tag naming conventions:
normalize() {
	echo "$1" | tr '[A-Z]' '[a-z]' | sed 's/[^a-z0-9._-]//g'
}

# Use the normalized project folder name:
PROJECT=$(normalize "$(basename "$PWD")")

# Iterate over all visible folders in the given directory:
for dir in $(ls -d */)
do
	cd "$dir"
		# Iterate over all branches:
		branches=$(git for-each-ref --format='%(refname:short)' refs/heads/)
		for branch in $branches; do
			# Ignore the master branch:
			[ "$branch" = 'master' ] && continue;
			# Ignore branches not on the same commit as the master branch:
			[ $(git show-ref -s refs/heads/$branch) != \
				$(git show-ref -s refs/heads/master) ] && continue;
			# Create a normalized image name:
			image="$PROJECT/$(normalize "$dir")"
			# Tag the latest (master) image with the branch name as version:
			echo "Tagging $image:$branch ..."
			docker tag -f "$image" "$image:$branch"
		done
	cd ..
done
