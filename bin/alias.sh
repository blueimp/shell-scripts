#!/bin/sh

#
# Useful alias commands.
#
# Usage: . ./alias.sh
#

# Simple static files web server:
alias srv='python3 -m http.server --bind 127.0.0.1'

# Print listening services:
alias listening='lsof -iTCP -sTCP:LISTEN -n -P +c0'
