#!/bin/sh

#
# Searches the chromium HSTS Preload List for the given hostname.
# Warning: downloads the source list (multiple MB in size) on every call.
#
# Usage: ./search-hsts-preload-list.sh hostname
#
# Requires curl and jq to be installed.
#

SOURCE_URL='https://chromium.googlesource.com/chromium/src/net/+/master/http/transport_security_state_static.json?format=TEXT'
HOSTNAME=${1:?}

curl -s "$SOURCE_URL" |
  base64 --decode |
  sed '/^ *\/\//d;/^\s*$/d' |
  jq -e --arg x "$HOSTNAME" '.entries[] | select(.name==$x)'
