#!/bin/sh

#
# Reloads the active tab of the given browser (defaults to Chrome).
# Keeps the browser window in the background (Chrome/Safari only).
#
# Usage: ./macos-reload-browser.sh [chrome|safari|firefox]
#

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

exec osascript -e "$OSASCRIPT"
