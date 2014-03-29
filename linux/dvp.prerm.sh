#!/bin/sh
set +x -e

# if argument given, normalize and use as root directory
[ -d "$1" ] && XKB_ROOT=$(readlink -f $1) || XKB_ROOT=/usr/share/X11/xkb

# check that these programs are available
which grep     1>/dev/null 2>&1 || exit 1
which sed      1>/dev/null 2>&1 || exit 2
which awk      1>/dev/null 2>&1 || exit 3
which xsltproc 1>/dev/null 2>&1 || exit 4

# some installations has an evdev in addition to a base rule
BASES=base
[ -e $XKB_ROOT/rules/evdev ] && BASES="$BASES evdev" || /bin/true
for base in $BASES; do

# remove all single lines added by the installer
sed -i '
/compose:102/d
/keypad:hex/d
/keypad:atm/d
/numpad:shift3/d
/kpdl:semi/d
' $XKB_ROOT/rules/$base
sed -i '
/dvp[\ \t]*us:/d
/compose:102/d
/keypad:hex/d
/keypad:atm/d
/numpad:shift3/d
/kpdl:semi/d
' $XKB_ROOT/rules/$base.lst

# remove all fragments added by the installer by matching them to a special
# comment which is then removed. this enables us to remove extranous whitespace
# that was added outside the node to provide proper indenting
TMP_FILE=$(mktemp $XKB_ROOT/rules/$base.xml.XXXXXX)
chmod 644 $TMP_FILE && \
xsltproc --nodtdattr --novalid - $XKB_ROOT/rules/$base.xml <<- __END__ | \
sed '/<!--DVP:REMOVE-->/d' | \
awk 'NR > 1 { print h } { h = $0 } END { ORS = ""; print h }' > $TMP_FILE && \
mv -f $TMP_FILE $XKB_ROOT/rules/$base.xml || \
rm $TMP_FILE
<?xml version="1.0" ?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output encoding="UTF-8" doctype-system="xkb.dtd"/>
<xsl:template match="xkbConfigRegistry/layoutList/layout/variantList/variant[configItem/name='dvp']">
   <xsl:comment>DVP:REMOVE</xsl:comment>
</xsl:template>
<xsl:template match="xkbConfigRegistry/optionList/group/option[configItem/name='numpad:shift3']">
   <xsl:comment>DVP:REMOVE</xsl:comment>
</xsl:template>
<xsl:template match="xkbConfigRegistry/optionList/group/option[configItem/name='keypad:hex']">
   <xsl:comment>DVP:REMOVE</xsl:comment>
</xsl:template>
<xsl:template match="xkbConfigRegistry/optionList/group/option[configItem/name='keypad:atm']">
   <xsl:comment>DVP:REMOVE</xsl:comment>
</xsl:template>
<xsl:template match="xkbConfigRegistry/optionList/group/option[configItem/name='kpdl:semi']">
   <xsl:comment>DVP:REMOVE</xsl:comment>
</xsl:template>
<xsl:template match="xkbConfigRegistry/optionList/group/option[configItem/name='compose:102']">
   <xsl:comment>DVP:REMOVE</xsl:comment>
</xsl:template>
<xsl:template match="/ | @* | node() ">
  <xsl:copy><xsl:apply-templates select="@* | node()" /></xsl:copy>
</xsl:template>
</xsl:stylesheet>
__END__

done # bases

# remove sections (from the opening brace up to and including the closing one)
# that were added by the installer script
# used to be: sed -i '/partial xkb_symbols "xxx" {/,/};/d' $XKB_ROOT/symbols/xxx
sed -i '/partial xkb_types "shift3" { include "shift3" };/d' $XKB_ROOT/types/numpad
sed -i '/partial modifier_keys xkb_symbols "102" { include "102" };/d' $XKB_ROOT/symbols/compose
sed -i '/partial alphanumeric_keys xkb_symbols "dvp" { include "dvp" };/d' $XKB_ROOT/symbols/us
sed -i '/partial keypad_keys xkb_symbols "ops" { include "ops" };/d' $XKB_ROOT/symbols/keypad
sed -i '/partial keypad_keys xkb_symbols "hex" { include "hex" };/d' $XKB_ROOT/symbols/keypad
sed -i '/partial keypad_keys xkb_symbols "atm" { include "atm" };/d' $XKB_ROOT/symbols/keypad
sed -i '/partial keypad_keys xkb_symbols "semi" { include "semi" };/d' $XKB_ROOT/symbols/kpdl
