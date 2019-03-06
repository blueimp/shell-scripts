#!/bin/sh

#
# Pulls or clones the repository given as url or directory.
# Fast-forward merges remote origin branches.
# Allows to run a command for each updated branch.
#
# Usage: ./pull-repository.sh [-b branches] [url|dir] [-- comand [args...]]
#
# The "-b" option defines a whitespace-separated list of branches to merge.
#
# Copyright 2016, Sebastian Tschan
# https://blueimp.net
#
# Licensed under the MIT license:
# https://opensource.org/licenses/MIT
#

# Exit immediately if a command exits with a non-zero status:
set -e

# Color codes:
c031='\033[0;31m' # red
c032='\033[0;32m' # green
c033='\033[0;33m' # yellow
c036='\033[0;36m' # cyan
c0='\033[0m' # no color

# Prints the given string in a highlight color:
highlight() {
  echo "${c036}$1${c0}"
}

# Prints the given string in a success color:
success() {
  echo "${c032}$1${c0}"
}

# Prints the given string in a warning color:
warning() {
  echo "${c033}$1${c0}"
}

# Prints the given string in an error color:
error() {
  echo "${c031}$1${c0}"
}

# Prints the given error message and exits:
error_exit() {
  error "$1" >&2
  echo "Usage: $0 [-b branches] [-c command] url" >&2
  exit 1
}

# Prints a list of all local branches that track an upstream branch:
local_upstream_branches() {
  git for-each-ref --format='%(refname:short) %(upstream)' refs/heads/ |
    grep -w refs/remotes | grep -Eo '^[^ ]+'
}

# Checks if the given branch exists:
branch_exists() {
  if ! git show-ref --verify -q "refs/remotes/origin/$1"; then
    echo "$(highlight "$1") $(warning 'not found')" >&2
    return 1
  fi
}

# Attempts a fast-forward merge for the given branch:
fast_forward_merge() {
  branch_exists "$1" || return $?
  status=0
  tracking_status=$(git for-each-ref --format='%(push:trackshort)' \
    "refs/heads/$1")
  if [ "$tracking_status" = '<>' ]; then
    echo "$(highlight "$1") $(error 'has diverged')" >&2
    return 1
  elif [ "$tracking_status" = '=' ]; then
    echo "$(highlight "$1") $(success 'is up-to-date')"
    return
  elif [ "$tracking_status" = '>' ]; then
    echo "$(highlight "$1") $(success 'is ahead')"
    return
  elif [ "$tracking_status" = '<' ]; then
    # Create a local copy of the remote branch:
    git branch --quiet "origin/$1" "origin/$1"
    # Put the working copy into a detached-head state, to allow branch merges:
    git checkout --detach --quiet
    # Attempt a fast-forward merge with the local copy of the remote branch:
    git fetch --quiet . "origin/$1:$1" || status=$?
    # Check out the previous working copy:
    git checkout --quiet -
    # Delete the local copy of the remote branch:
    git branch -D --quiet "origin/$1"
  else
    # The remote branch has not been fetched yet:
    git fetch --quiet origin "$1:$1" || status=$?
  fi
  if [ $status -eq 0 ]; then
    echo "$(highlight "$1") $(success 'has been updated')"
  else
    echo "$(highlight "$1") $(error 'update failed')" >&2
  fi
  return $status
}

# Checks if fast-forward merge is enabled:
fast_forward_merge_enabled() {
  if [ "$(git config merge.ff)" = 'no' ]; then
    error 'git fast-forward merge disabled' >&2
    global_arg=
    [ "$(git config --global merge.ff)" = 'no' ] && global_arg=' --global'
    echo 'Run the following command to enable it:' >&2
    highlight "git config$global_arg merge.ff yes" >&2
    exit 1
  fi
}

# Returns the selected branches:
get_branches() {
  if [ -z "$BRANCHES" ]; then
    BRANCHES=$(local_upstream_branches)
  fi
  printf %s "$BRANCHES"
}

# Pulls the selected branches of the given repository directory:
pull() {
  cd "$1"
  fast_forward_merge_enabled || return $?
  git fetch --quiet origin
  pull_status=0
  for branch in $(get_branches); do
    fast_forward_merge "$branch" || pull_status=$?
  done
  return $pull_status
}

# Clones the given repository url:
clone() {
  if git clone --quiet "$1" "$2"; then
    echo "$(highlight "$2") $(success 'cloned')"
    cd "$2"
  else
    echo "$(highlight "$1") $(error 'clone failed')" >&2
    return 1
  fi
}

# Clones or pulls the given repository:
update_repository() {
  if [ -d "$1" ]; then
    pull "$1"
  else
    repo_base=$(basename "$1")
    dir=${repo_base%.git}
    if [ -d "$dir" ]; then
      pull "$dir"
    else
      clone "$1" "$dir"
    fi
  fi
  return $?
}

# Checks out the given branch, throwing away local changes:
clean_checkout() {
  git checkout --force --quiet "$1"
}

# Runs the COMMAND on the given branch:
execute_on_branch() {
  branch_exists "$1" || return $?
  branch=$1
  shift
  stashed=false
  if ! git diff --quiet || ! git diff --cached --quiet; then
    # Stash the current working directory changes:
    git stash --quiet
    stashed=true
  fi
  # Remember the current branch:
  current_branch=$(git rev-parse --abbrev-ref HEAD)
  # Checkout the given one:
  [ "$current_branch" != "$branch" ] && clean_checkout "$branch"
  status=0
  # Execute the given command:
  eval "$@" || status=$?
  # Checkout the original branch:
  [ "$current_branch" != "$branch" ] && clean_checkout "$current_branch"
  if [ "$stashed" = true ]; then
    # Re-apply the stashed changes:
    git stash pop --quiet
  fi
  return $status
}

# Execute the given command on each selected branch:
execute() {
  [ "$#" -eq 0 ] && return
  execute_status=0
  for branch in $(get_branches); do
    execute_on_branch "$branch" "$@" || execute_status=$?
  done
  return $execute_status
}

if [ "$1" = -b ]; then
  BRANCHES=$2
  shift 2
fi

if [ "$2" = -- ]; then
  REPO=$1
  shift 2
elif [ "$1" = -- ]; then
  REPO=.
  shift
elif [ -n "$1" ]; then
  REPO=$1
  shift
else
  REPO=.
fi

update_repository "$REPO"
execute "$@"
