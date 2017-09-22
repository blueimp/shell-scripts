#!/bin/sh

#
# Prints the expirations dates for the given certificate files.
#
# Requires openssl to be installed.
#
# Usage: ./cert-expiration-dates.sh cert1 [cert2 ...]
#
# Highlights certs expiring in 28 days in yellow warning color.
# Highlights certs expiring in 14 days in red warning color.
#
# Returns exit code 1 if any certs will be expired in the next 14 days.
# Returns exit code 0 otherwise.
#
# Copyright 2017, Sebastian Tschan
# https://blueimp.net
#
# Licensed under the MIT license:
# https://opensource.org/licenses/MIT
#

set -e

get_padding() {
  padding=0
  for cert; do
    if [ ${#cert} -gt $padding ]; then
      padding=${#cert};
    fi
  done
  echo "$padding"
}

expires_in_days() {
  ! openssl x509 -checkend $((60*60*24*$2)) -noout -in "$1"
}

print_expiration_date() {
  openssl x509 -enddate -noout -in "$1" | sed 's/notAfter=//'
}

print_expiration_dates() {
  for cert; do
    if expires_in_days "$cert" 14; then
      STATUS=1
      color="${c031}"
    elif expires_in_days "$cert" 28; then
      color="${c033}"
    else
      color="${c032}"
    fi
    printf "${c036}%s${c0} %s expires on $color%s${c0}\n" "$cert" \
      "$(printf "%-$((PADDING-${#cert}))s" | tr ' ' '-')" \
      "$(print_expiration_date "$cert")"
  done
}

# Color codes:
c031='\033[0;31m' # red
c032='\033[0;32m' # green
c033='\033[0;33m' # yellow
c036='\033[0;36m' # cyan
c0='\033[0m' # no color

PADDING="$(get_padding "$@")"

STATUS=0

print_expiration_dates "$@"

exit $STATUS
