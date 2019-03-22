#!/bin/sh

#
# Creates a GitHub release or pre-release for tagged commits.
# Uploads the given files as release assets.
#
# Requires git, curl and jq.
#
# Usage: ./github-release.sh [--no-color] [FILE ...]
#
# The --no-color argument allows to disable the default color output.
#

set -e

# Colorize the output by default:
if [ "$1" != '--no-color' ]; then
  c031='\033[0;31m' # red
  c032='\033[0;32m' # green
  c033='\033[0;33m' # yellow
  c036='\033[0;36m' # cyan
  c0='\033[0m' # no color
else
  shift 1
  c031=
  c032=
  c033=
  c036=
  c0=
fi

if [ -z "$GITHUB_TOKEN" ]; then
  printf "${c031}Error${c0}: Missing ${c033}%s${c0} environment variable.\\n" \
    GITHUB_TOKEN >&2
  exit 1
fi

# Check if the current directory is a git repository:
git -C . rev-parse

ORIGIN_URL=$(git config --get remote.origin.url)
GITHUB_ORG=$(echo "$ORIGIN_URL" | sed 's|.*:||;s|/.*$||')
GITHUB_REPO=$(echo "$ORIGIN_URL" | sed 's|.*/||;s|\.[^\.]*$||')
export GITHUB_ORG
export GITHUB_REPO

# Get the tag for the current commit:
TAG="$(git describe --exact-match --tags 2> /dev/null || true)"

if [ -z "$TAG" ]; then
  printf "${c033}%s${c0}: Not a tagged commit\\n" Warning
  exit
fi

# Check if this is a pre-release version (denoted by a hyphen):
if [ "${TAG#*-}" != "$TAG" ]; then
  PRE=true
else
  PRE=false
fi

RELEASE_TEMPLATE='{
  "tag_name": "%s",
  "name": "%s",
  "prerelease": %s,
  "draft": %s
}'

create_draft_release() {
  # shellcheck disable=SC2059
  data="$(printf "$RELEASE_TEMPLATE" "$TAG" "$TAG" "$PRE" true)"
  if output=$(curl \
      --silent \
      --fail \
      --request POST \
      --header "Authorization: token $GITHUB_TOKEN" \
      --header 'Content-Type: application/json' \
      --data "$data" \
      "https://api.github.com/repos/$GITHUB_ORG/$GITHUB_REPO/releases");
  then
    RELEASE_ID=$(echo "$output" | jq -re '.id')
    UPLOAD_URL_TEMPLATE=$(echo "$output" | jq -re '.upload_url')
  fi
}

upload_release_asset() {
  mime_type=$(file -b --mime-type "$1")
  curl \
    --silent \
    --fail \
    --request POST \
    --header "Authorization: token $GITHUB_TOKEN" \
    --header "Content-Type: $mime_type" \
    --data-binary "@$1" \
    "${UPLOAD_URL_TEMPLATE%\{*}?name=$(basename "$1")" \
    > /dev/null
}

publish_release() {
  # shellcheck disable=SC2059
  data="$(printf "$RELEASE_TEMPLATE" "$TAG" "$TAG" "$PRE" false)"
  curl \
    --silent \
    --fail \
    --request PATCH \
    --header "Authorization: token $GITHUB_TOKEN" \
    --header 'Content-Type: application/json' \
    --data "$data" \
    "https://api.github.com/repos/$GITHUB_ORG/$GITHUB_REPO/releases/$1" \
    > /dev/null
}

printf "Creating draft release ${c036}%s${c0} ... " "$TAG"
create_draft_release \
  && echo "${c032}done${c0}" || echo "${c031}fail${c0}"

for FILE; do
  if [ ! -f "$FILE" ] || [ ! -r "$FILE" ]; then
    printf "${c031}%s${c0}: Not a readable file: ${c036}%s${c0}\\n" \
      Error "$FILE"
    continue
  fi
  printf "Uploading ${c036}%s${c0} ... " "$FILE"
  upload_release_asset "$FILE" \
    && echo "${c032}done${c0}" || echo "${c031}fail${c0}"
done

printf "Publishing release ${c036}%s${c0} ... " "$TAG"
publish_release "$RELEASE_ID" \
  && echo "${c032}done${c0}" || echo "${c031}fail${c0}"
