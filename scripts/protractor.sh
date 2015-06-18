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
# The SELENIUM_HUB environment variable can be set to a running hub container.
# Example: SELENIUM_HUB=$(docker run -d $SELENIUM_IMAGE) ./protractor.sh
#
# Copyright 2015, Sebastian Tschan
# https://blueimp.net
#
# Licensed under the MIT license:
# http://www.opensource.org/licenses/MIT
#

# Exit immediately if a command exits with a non-zero status:
set -e

if [ -z "$PROTRACTOR_VERSION" ]
then
  PROTRACTOR_VERSION="2.1.0"
fi

if [ -z "$SELENIUM_VERSION" ]
then
  SELENIUM_VERSION="2.46.0"
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

PROTRACTOR_IMAGE="blueimp/protractor:$PROTRACTOR_VERSION"
SELENIUM_IMAGE="selenium/hub:$SELENIUM_VERSION"

WORKDIR="/home/protractor"
VOLUME="$PWD:$WORKDIR"

HOSTNAME="hub"
URL="http://$HOSTNAME:4444/wd/hub"

function cleanup {
  # Stop and remove browser nodes:
  CIDS=$(docker stop ${CIDS[@]})
  CIDS=$(docker rm -v $CIDS)
  if [ -z "$SELENIUM_HUB" ]
  then
    # Stop and remove the selenium hub:
    HUB=$(docker stop $HUB)
    HUB=$(docker rm -v $HUB)
  fi
}

# Clean up on SIGTERM and EXIT:
trap "cleanup; exit" SIGTERM EXIT

if [ -z "$SELENIUM_HUB" ]
then
  # Start selenium hub:
  HUB=$(docker run -d $SELENIUM_IMAGE)
else
  # Use existing hub:
  HUB=$SELENIUM_HUB
fi

LINK=$HUB:$HOSTNAME

# Only run the matching nodes:
NODES=($(printf "%s\n" "${NODES[@]}" | grep -E "$SELENIUM_NODES"))

CIDS=()

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
docker run --rm -v "$VOLUME" --link $LINK $PROTRACTOR_IMAGE "$@"
