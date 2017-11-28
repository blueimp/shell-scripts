#!/bin/sh
# shellcheck shell=dash

#
# Retrieves all secrets from the AWS SSM Parameter Store.
#
# Usage: ./aws-ssm-secrets.sh
#
# Requires aws and jq to be installed.
#
# Copyright 2017, Sebastian Tschan
# https://blueimp.net
#
# Licensed under the MIT license:
# https://opensource.org/licenses/MIT
#

set -e

get_params() {
  local response
  local params
  local secrets
  local next_token

  response=$(
    aws ssm describe-parameters  \
      --filters Key=Type,Values=SecureString \
      --max-items 10 \
      "$@"
  )
  params=$(echo "$response" | jq -r '.Parameters[]')

  # shellcheck disable=SC2046
  secrets=$(
    aws ssm get-parameters \
      --with-decryption \
      --names \
        $(echo "$response" | jq -r '.Parameters[].Name') | jq -r '.Parameters[]'
  )

  printf '%s\n' "$params" "$secrets"

  next_token=$(echo "$response" | jq -re '.NextToken')
  if [ ! -z "$next_token" ]; then
    get_params --starting-token "$next_token"
  fi
}

# Combine params and secrets into unique objects based on their name:
get_params | jq --slurp --sort-keys 'group_by(.Name) | map(.[0]+.[1])'
