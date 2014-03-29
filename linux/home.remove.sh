#!/bin/sh
set +x -e

# if argument given, normalize and use as root directory
[ -d "$1" ] && TARGET=$(readlink -f $1) || TARGET=$(readlink -f ~/.kbddvp)

# find our own location
DVP_DIR=$(dirname $(readlink -f $0))

# check that these programs are available
which grep     1>/dev/null 2>&1 || exit 1
which uniq     1>/dev/null 2>&1 || exit 2
which xargs    1>/dev/null 2>&1 || exit 3

# files that are modified by the installer program
FILES="rules/base rules/base.lst rules/base.xml types/numpad \
       symbols/compose symbols/us symbols/keypad symbols/kpdl"

# run the uninstaller to remove the files that were copied there from the main distribution
# (don't bother to remove it from the configuration, as it will be removed next)
$DVP_DIR/dvp.remove.sh $TARGET || true

# remove files that were copied there from the system files
for f in $FILES; do
[ -e $TARGET/$f ] && rm -f $TARGET/$f;
done

# remove directories
for d in $((for f in $FILES; do echo $(dirname $f); done) | uniq | xargs); do
rmdir --ignore-fail-on-non-empty $TARGET/$d
done
rmdir --ignore-fail-on-non-empty $TARGET

# remove the settings from the profile that it run when logging on
for c in ~/.xprofile; do
TMP_FILE=$(mktemp $c.XXXXXX)
grep -v "\[ -e ~/\.Xkbmap \] && setxkbmap -option \"\" \$(cat ~/\.Xkbmap) -rules .* -print | xkbcomp -w 0 -I.* - \$DISPLAY" $c > $TMP_FILE
[ -e $c ] && mv -f $c $c~;
mv -f $TMP_FILE $c;
done