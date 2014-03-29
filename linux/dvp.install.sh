#!/bin/sh
set +x -e

# if argument given, normalize and use as root directory
[ -d "$1" ] && XKB_ROOT=$(readlink -f $1) || XKB_ROOT=/usr/share/X11/xkb

# owner may be given as the second argument, for local installation
[ -n "$2" ] && OWNER=$2 || OWNER=root

# find our own location
DVP_DIR=$(dirname $(readlink -f $0))

# copy files to the appropriate location
for f in dvp hex atm 102 ops semi; do 
	install -m 644 -o $OWNER -g $OWNER $DVP_DIR/$f.xkb $XKB_ROOT/symbols/$f; 
done
for f in shift3; do
	install -m 644 -o $OWNER -g $OWNER $DVP_DIR/$f.xkb $XKB_ROOT/types/$f;
done


