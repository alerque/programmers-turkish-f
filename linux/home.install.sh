#!/bin/sh
set +x -e

# if argument given, normalize and use as root directory
[ -d "$1" ] && TARGET=$(readlink -f $1) || TARGET=$(readlink -f ~/.kbddvp)
[ -d "$2" ] && XKB_ROOT=$(readlink -f $2) || XKB_ROOT=/usr/share/X11/xkb

# find our own location
DVP_DIR=$(dirname $(readlink -f $0))

# check that these programs are available
which grep     1>/dev/null 2>&1 || exit 1

# files that are modified by the installer program
FILES="rules/base rules/base.lst rules/base.xml types/numpad \
       symbols/compose symbols/us symbols/keypad symbols/kpdl" \

# copy master files from X.org distribution into our private directory
for f in $FILES; do
mkdir -p $TARGET/$(dirname $f);
cp -f $XKB_ROOT/$f $TARGET/$f;
done

# run the installer on our private copy
$DVP_DIR/dvp.install.sh $TARGET $(whoami) && \
$DVP_DIR/dvp.postinst.sh $TARGET

# add a line in .xprofile to load it properly
# (or maybe ~/.xsessionrc; see <http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=411639>)
for c in ~/.xprofile; do
[ -e $c ] && cp -f $c $c~;
grep -c "\[ -e ~/\.Xkbmap \] && setxkbmap -option \"\" \$(cat ~/\.Xkbmap) -rules .* -print | xkbcomp -w 0 -I.* - \$DISPLAY" $c || \
cat >> $c << __EOF__
[ -e ~/.Xkbmap ] && setxkbmap -option "" \$(cat ~/.Xkbmap) -rules $TARGET/rules/base -print | xkbcomp -w 0 -I$TARGET - \$DISPLAY
__EOF__
done