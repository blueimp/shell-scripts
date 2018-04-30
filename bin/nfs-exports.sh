#!/bin/sh

#
# Configures the given NFS export directories.
# Also sets nfs.server.mount.require_resv_port option to 0.
#
# Requires sed, tee, nfsd.
#
# Usage: ./nfs-exports.sh [dir ...]
#

set -e

MARKER='### nfs exports'
START="$MARKER start ###"
END="$MARKER end ###"
NL='
'
MAPALL="$(id -u):$(id -g)"
NFS_OPT=nfs.server.mount.require_resv_port

NFS_CONF=$(sed "/^$NFS_OPT.*/d" /etc/nfs.conf)
EXPORTS=$(sed "/$START/,/$END/d" /etc/exports)

NFS_CONF="$NFS_CONF${NL}nfs.server.mount.require_resv_port=0"

if [ "$#" -gt 0 ]; then
  EXPORTS="$EXPORTS${NL}$START"
  for DIR in "$@"; do
    DIR=$(cd "$DIR" && pwd)
    EXPORTS="$EXPORTS${NL}$DIR -alldirs -mapall=$MAPALL 127.0.0.1"
  done
  EXPORTS="$EXPORTS${NL}$END"
fi

echo "$NFS_CONF" | sed '/./,$!d' | sudo tee /etc/nfs.conf > /dev/null
echo "$EXPORTS" | sed '/./,$!d' | sudo tee /etc/exports > /dev/null
sudo nfsd checkexports
sudo nfsd restart
