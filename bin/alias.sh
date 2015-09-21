#!/bin/sh

#
# Print alias statements for commands executed in docker containers.
#
# Usage: ./alias.sh [project_name]
#
# Containers are identified via docker-compose service labels.
# Accepts an alternative docker-compose project name as argument.
#
# Copyright 2015, Sebastian Tschan
# https://blueimp.net
#
# Licensed under the MIT license:
# http://www.opensource.org/licenses/MIT
#

# The escaped bin dir path:
BIN="'$(cd "$(dirname "$0")" && pwd | sed "s/'/'\\\''/g")'"

# Accept an alternative docker-compose project name as argument:
PROJECT=$1

# Prints the command to retrieve the CONTAINER ID for a given service name:
cid() { echo '"$('$BIN'/cid.sh '$1 $PROJECT')"'; }

############ alias definitions start ############
alias redis-cli="docker exec -it -u redis $(cid redis) redis-cli"

alias mongo="docker exec -it -u mongodb $(cid mongodb) mongo"
alias mongodump="MONGODB_CONTAINER=$(cid mongodb) $BIN/mongodump.sh"
alias mongorestore="MONGODB_CONTAINER=$(cid mongodb) $BIN/mongorestore.sh"

alias php="docker exec -it -u www-data $(cid php) php"
alias phpunit="docker exec -u www-data $(cid php) phpunit"
alias composer="docker exec -it -u www-data $(cid php) composer"
############ alias definitions end ############

# Print the alias statements:
alias | sed 's/^/alias /'
