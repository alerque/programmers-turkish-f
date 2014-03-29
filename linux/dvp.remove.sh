#!/bin/sh
set +x -e

# if argument given, normalize and use as root directory
[ -d "$1" ] && XKB_ROOT=$(readlink -f $1) || XKB_ROOT=/usr/share/X11/xkb

# remove files from the file system
for f in dvp hex atm 102 ops semi; do 
	[ -f $XKB_ROOT/symbols/$f ] && rm -f $XKB_ROOT/symbols/$f;
done
for f in shift3; do
	[ -f $XKB_ROOT/types/$f ] && rm -f $XKB_ROOT/types/$f;
done
