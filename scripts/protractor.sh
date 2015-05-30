#!/bin/bash

#
# Run Protractor and Selenium Grid as docker containers.
#
# This script accepts the same arguments as the protractor CLI:
# Usage: ./protractor.sh [options] [configFile]
#
# The configFile must be in a subdirectory of the current working directory.
# If no configFile argument is given, it defaults to protractor.conf.js.
# Without a configFile, specs must be provided via --specs argument.
# Example: ./protractor.sh --specs e2e/todo-spec.js
#
# The SELENIUM_NODES environment variable filters the list of browser nodes.
# It is used as extended regular expression pattern with the grep command.
# The pattern is matched against a predefined list of nodes.
# This allows to select debug nodes with integrated VNC server:
# Example: SELENIUM_NODES="chrome-debug" ./protractor.sh
#
# Copyright 2015, Sebastian Tschan
# https://blueimp.net
#
# Licensed under the MIT license:
# http://www.opensource.org/licenses/MIT
#

if [ -z "$PROTRACTOR_VERSION" ]
then
  PROTRACTOR_VERSION="2.1.0"
fi

if [ -z "$SELENIUM_VERSION" ]
then
  SELENIUM_VERSION="2.45.0"
fi

if [ -z "$SELENIUM_NODES" ]
then
  SELENIUM_NODES="chrome:|firefox:"
fi

NODES=()
NODES[0]="selenium/node-chrome:$SELENIUM_VERSION"
NODES[1]="selenium/node-firefox:$SELENIUM_VERSION"
NODES[2]="selenium/node-chrome-debug:$SELENIUM_VERSION"
NODES[3]="selenium/node-firefox-debug:$SELENIUM_VERSION"

LABEL="protractor=$PROTRACTOR_VERSION"
IMAGE="protractor:$PROTRACTOR_VERSION"
SELENIUM_LABEL="selenium-hub=$SELENIUM_VERSION"
SELENIUM_IMAGE="selenium/hub:$SELENIUM_VERSION"

WORKDIR="/home/protractor"
VOLUME="$PWD:$WORKDIR"

HOSTNAME="hub"
URL="http://$HOSTNAME:4444/wd/hub"

DOCKERFILE="
FROM node:0.10

# node-gyp dependency build requires --unsafe-perm option:
RUN npm install -g --unsafe-perm protractor@$PROTRACTOR_VERSION

# Add protractor system group/user with gid/uid 1000.
# This is a workaround for boot2docker issue #581, see
# https://github.com/boot2docker/boot2docker/issues/581
RUN groupadd -g 1000 protractor
RUN useradd -g protractor -u 1000 protractor

USER protractor
WORKDIR $WORKDIR
ENTRYPOINT [\"protractor\"]

LABEL $LABEL
"

# Check if protractor image exists:
if [ -z "$(docker images -q -f label=$LABEL)" ]
then
  # Build and tag protractor image:
  echo "$DOCKERFILE" | docker build -t protractor -
  docker tag protractor:latest $IMAGE
fi

# Check if selenium hub has been created:
HUB=$(docker ps -a -q -f label=$SELENIUM_LABEL)

if [ -z "$HUB" ]
then
  # Start selenium hub:
  HUB=$(docker run -d -l $SELENIUM_LABEL $SELENIUM_IMAGE)
else
  HUB=$(docker restart $HUB)
fi

CIDS=()

function cleanup {
  # Stop and remove browser nodes:
  CIDS=$(docker stop ${CIDS[@]})
  CIDS=$(docker rm -v $CIDS)
  # Stop the selenium hub:
  HUB=$(docker stop $HUB)
}

# Clean up on SIGTERM and EXIT:
trap "cleanup; exit" SIGTERM EXIT

LINK=$HUB:$HOSTNAME

# Only run the matching nodes:
NODES=($(printf "%s\n" "${NODES[@]}" | grep -E "$SELENIUM_NODES"))

# Start and register browser nodes:
for INDEX in ${!NODES[@]}
do
	NODE=${NODES[$INDEX]}
  if [[ $NODE == *debug* ]]
  then
    # Debug nodes run with an integrated VNC server:
    CIDS[$INDEX]=$(docker run -d -v "$VOLUME" --link $LINK -P $NODE)
    VNC_PORT=$(docker port ${CIDS[$INDEX]} 5900 | cut -d : -f 2)
    echo "open vnc://\$DOCKER_HOST_IP:$VNC_PORT"
    echo "vnc password: 'secret'"
    read -p "Press [Enter] to continue..."
    continue
  fi
  CIDS[$INDEX]=$(docker run -d -v "$VOLUME" --link $LINK $NODE)
done

# Add the selenium hub address as argument:
set -- "$@" --seleniumAddress "$URL"

# Run the given e2e test suite:
docker run --rm -v "$VOLUME" --link $LINK $IMAGE "$@"
