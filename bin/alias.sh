#!/bin/sh

#
# Print alias statements for commands executed in docker containers.
#
# Usage: ./alias.sh [project_name]
#
# Copyright 2015, Sebastian Tschan
# https://blueimp.net
#
# Licensed under the MIT license:
# http://www.opensource.org/licenses/MIT
#

# Exit immediately if a command exits with a non-zero status:
set -e

# The escaped bin dir path:
BIN="'$(cd "$(dirname "$0")" && pwd | sed "s/'/'\\\''/g")'"

############ alias definitions start ############
alias cid=$BIN'/cid.sh'

alias redis-cli='docker exec -it "$(cid redis)" gosu redis redis-cli'

alias mongo='docker exec -it "$(cid mongodb)" gosu mongodb mongo'
alias mongodump='MONGODB_CONTAINER="$(cid mongodb)" '$BIN'/mongodump.sh'
alias mongorestore='MONGODB_CONTAINER="$(cid mongodb)" '$BIN'/mongorestore.sh'

alias php='docker exec "$(cid php)" gosu www-data php'
alias phpunit='docker exec "$(cid php)" gosu www-data phpunit'
alias composer='docker exec "$(cid php)" gosu www-data composer'
############ alias definitions end ############

# Print the alias statements:
alias | sed 's/^/alias /'
