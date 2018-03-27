#!/bin/sh

#
# Reloads the active tab of the given browser (defaults to Chrome).
# Keeps the browser window in the background (Chrome/Safari only).
# Can optionally execute a given command before reloading the browser tab.
# Browser reloading is supported on MacOS only for now.
#
# Usage: ./reload-browser.sh [chrome|safari|firefox] -- [command args...] 
#

set -e

RELOAD_CHROME='tell application "Google Chrome"
  reload active tab of window 1
end tell'

RELOAD_SAFARI='tell application "Safari"
  set URL of document 1 to (URL of document 1)
end tell'

RELOAD_FIREFOX='activate application "Firefox"
tell application "System Events" to keystroke "r" using command down'

case "$1" in
  firefox)  OSASCRIPT=$RELOAD_FIREFOX;;
  safari)   OSASCRIPT=$RELOAD_SAFARI;;
  *)        OSASCRIPT=$RELOAD_CHROME;;
esac

if shift; then
  [ "$1" = "--" ] && shift
  "$@"
fi

if command -v osascript > /dev/null 2>&1; then
  exec osascript -e "$OSASCRIPT"
fi
