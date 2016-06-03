#!/bin/sh

#
# Checks if a given docker image exists.
#
# Usage: ./docker-image-exists.sh image[:tag]
#
# Requires curl and jq to be installed.
#
# Copyright 2016, Sebastian Tschan
# https://blueimp.net
#
# Licensed under the MIT license:
# http://www.opensource.org/licenses/MIT
#

# Exit immediately if a command exits with a non-zero status:
set -e

if [ -z "$1" ]; then
  echo 'Usage: ./docker-image-exists.sh image[:tag]' >&2
  exit 1
fi

# Absolute path to the project dir:
PROJECT_DIR="$(cd "$(dirname "$0")/../" && pwd)"

# Parse aguments:
IMAGE="${1%:*}"
TAG="${1##*:}"
if [ "$IMAGE" = "$TAG" ]; then
  TAG=latest
fi

# Retrieve Docker Basic Authentication token:
BASIC_AUTH="$(cat "$HOME/.docker/config.json" |
  jq -r '.auths["https://index.docker.io/v1/"].auth')"

# Define Docker access scope:
SCOPE="repository:$IMAGE:pull"

# Define the Docker token and registry URLs:
TOKEN_URL="https://auth.docker.io/token?service=registry.docker.io&scope=$SCOPE"
REGISTRY_URL="https://registry-1.docker.io/v2/$IMAGE/manifests/$TAG"

# Retrieve the access token:
TOKEN="$(curl -sSL -H "Authorization: Basic $BASIC_AUTH" "$TOKEN_URL" |
  jq -r '.token')"

# Check if the given image tag exists:
curl -fsSLI -o /dev/null -H "Authorization: Bearer $TOKEN" "$REGISTRY_URL"
