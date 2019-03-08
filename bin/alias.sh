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

# Prints a random alphanumeric characters string with the given length:
alias random='LC_ALL=C tr -dc A-Za-z0-9 < /dev/urandom | head -c'
