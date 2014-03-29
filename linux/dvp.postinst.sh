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

# see <http://www.grymoire.com/Unix/Sed.html#uh-40> for a tutorial
# all changes are prefixed by a guard to ensure indempotency
grep -c 'numpad:shift3' $XKB_ROOT/rules/$base 1>/dev/null || \
sed -i '
/\!\ option\t=\ttypes/a\
  numpad:shift3                 =       +numpad(microsoft)+numpad(shift3)
' $XKB_ROOT/rules/$base
grep -c 'compose:102' $XKB_ROOT/rules/$base 1>/dev/null || \
sed -i '
/\!\ option\t=\tsymbols/a\
  compose:102           =       +compose(102)
' $XKB_ROOT/rules/$base
# note: first entry inserted in the symbols section will end up
# furthest down. broader definitions (those that include legacy)
# must appear earlier in the file so they don't override
# specializations
grep -c 'kpdl:semi' $XKB_ROOT/rules/$base 1>/dev/null || \
sed -i '
/\!\ option\t=\tsymbols/a\
  kpdl:semi             =       +kpdl(semi)
' $XKB_ROOT/rules/$base
grep -c 'keypad:atm' $XKB_ROOT/rules/$base 1>/dev/null || \
sed -i '
/\!\ option\t=\tsymbols/a\
  keypad:atm            =       +keypad(ops)+keypad(hex)+keypad(atm)
' $XKB_ROOT/rules/$base
grep -c 'keypad:hex' $XKB_ROOT/rules/$base 1>/dev/null || \
sed -i '
/\!\ option\t=\tsymbols/a\
  keypad:hex            =       +keypad(ops)+keypad(hex)
' $XKB_ROOT/rules/$base

grep -c 'dvp[\ \t]*us:' $XKB_ROOT/rules/$base.lst 1>/dev/null || \
sed -i '
/\!\ variant/a\
  dvp             us: Programmer Dvorak
' $XKB_ROOT/rules/$base.lst
grep -c 'numpad:shift3' $XKB_ROOT/rules/$base.lst 1>/dev/null || \
sed -i '
/\ \{2\}compat\ \{15\}Miscellaneous\ compatibility\ options/a\
  numpad:shift3        Shift does not affect NumLock.
' $XKB_ROOT/rules/$base.lst
grep -c 'keypad:hex' $XKB_ROOT/rules/$base.lst 1>/dev/null || \
sed -i '
/\ \{2\}keypad\ \{15\}Keypad\ layout\ selection/a\
  keypad:hex           Hexadecimal keypad.
' $XKB_ROOT/rules/$base.lst
grep -c 'keypad:atm' $XKB_ROOT/rules/$base.lst 1>/dev/null || \
sed -i '
/\ \{2\}keypad\ \{15\}Keypad\ layout\ selection/a\
  keypad:atm           ATM/phone-style keypad.
' $XKB_ROOT/rules/$base.lst
grep -c 'compose:102' $XKB_ROOT/rules/$base.lst 1>/dev/null || \
sed -i '
/\ \{2\}Compose\ key\ \{10\}Compose\ key\ position/a\
  compose:102          Less-than/greater-than is Compose.
' $XKB_ROOT/rules/$base.lst
grep -c 'kpdl:semi' $XKB_ROOT/rules/$base.lst 1>/dev/null || \
sed -i '
/\ \{2\}kpdl\ \{17\}Numeric\ keypad\ delete\ key\ behaviour/a\
  kpdl:semi            Dot, with semi-colon on third level
' $XKB_ROOT/rules/$base.lst

# insert fragment in the appropriate place, otherwise preserving the original
# document as-is. style to a temporary file and afterwards overwrite the target
# (removing the temporary file in the process). the awk command is for stripping
# the final newline character.
COUNT=$(grep -c "<name>dvp</name>" $XKB_ROOT/rules/$base.xml) || true
if [ $COUNT -eq 0 ]; then
TMP_FILE=$(mktemp $XKB_ROOT/rules/$base.xml.XXXXXX)
chmod 644 $TMP_FILE && \
xsltproc --nodtdattr --novalid - $XKB_ROOT/rules/$base.xml <<- __END__ | \
awk 'NR > 1 { print h } { h = $0 } END { ORS = ""; print h }' > $TMP_FILE && \
mv -f $TMP_FILE $XKB_ROOT/rules/$base.xml || \
rm $TMP_FILE
<?xml version="1.0" ?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output encoding="UTF-8" doctype-system="xkb.dtd"/>
<xsl:template match="xkbConfigRegistry/layoutList/layout/variantList[preceding-sibling::configItem/name='us']">
  <xsl:copy>
    <xsl:apply-templates select="@*|node()"/>
    <xsl:text disable-output-escaping="yes"><![CDATA[  <variant>
          <configItem>
            <name>dvp</name>
            <description>Programmer Dvorak</description>
          </configItem>
        </variant>
      ]]></xsl:text>
  </xsl:copy>
</xsl:template>
<xsl:template match="/ | @* | node() ">
  <xsl:copy><xsl:apply-templates select="@* | node()" /></xsl:copy>
</xsl:template>
</xsl:stylesheet>
__END__
fi

# same procedure for the hexadecimal keypad and European compose key
COUNT=$(grep -c "<name>numpad:shift3</name>" $XKB_ROOT/rules/$base.xml) || true
if [ $COUNT -eq 0 ]; then
TMP_FILE=$(mktemp $XKB_ROOT/rules/$base.xml.XXXXXX)
chmod 644 $TMP_FILE && \
xsltproc --nodtdattr --novalid - $XKB_ROOT/rules/$base.xml <<- __END__ | \
awk 'NR > 1 { print h } { h = $0 } END { ORS = ""; print h }' > $TMP_FILE && \
mv -f $TMP_FILE $XKB_ROOT/rules/$base.xml || \
rm $TMP_FILE
<?xml version="1.0" ?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output encoding="UTF-8" doctype-system="xkb.dtd"/>
<xsl:template match="xkbConfigRegistry/optionList/group[configItem/name='compat']">
  <xsl:copy>
    <xsl:apply-templates select="@*|node()"/>
    <xsl:text disable-output-escaping="yes"><![CDATA[  <option>
        <configItem>
          <name>numpad:shift3</name>
          <description>Shift does not affect NumLock.</description>
        </configItem>
      </option>
    ]]></xsl:text>
  </xsl:copy>
</xsl:template>
<xsl:template match="/ | @* | node() ">
  <xsl:copy><xsl:apply-templates select="@* | node()" /></xsl:copy>
</xsl:template>
</xsl:stylesheet>
__END__
fi

COUNT=$(grep -c "<name>keypad:hex</name>" $XKB_ROOT/rules/$base.xml) || true
if [ $COUNT -eq 0 ]; then
TMP_FILE=$(mktemp $XKB_ROOT/rules/$base.xml.XXXXXX)
chmod 644 $TMP_FILE && \
xsltproc --nodtdattr --novalid - $XKB_ROOT/rules/$base.xml <<- __END__ | \
awk 'NR > 1 { print h } { h = $0 } END { ORS = ""; print h }' > $TMP_FILE && \
mv -f $TMP_FILE $XKB_ROOT/rules/$base.xml || \
rm $TMP_FILE
<?xml version="1.0" ?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output encoding="UTF-8" doctype-system="xkb.dtd"/>
<xsl:template match="xkbConfigRegistry/optionList/group[configItem/name='keypad']">
  <xsl:copy>
    <xsl:apply-templates select="@*|node()"/>
    <xsl:text disable-output-escaping="yes"><![CDATA[  <option>
        <configItem>
          <name>keypad:hex</name>
          <description>Hexadecimal keypad.</description>
        </configItem>
      </option>
    ]]></xsl:text>
  </xsl:copy>
</xsl:template>
<xsl:template match="/ | @* | node() ">
  <xsl:copy><xsl:apply-templates select="@* | node()" /></xsl:copy>
</xsl:template>
</xsl:stylesheet>
__END__
fi

COUNT=$(grep -c "<name>keypad:atm</name>" $XKB_ROOT/rules/$base.xml) || true
if [ $COUNT -eq 0 ]; then
TMP_FILE=$(mktemp $XKB_ROOT/rules/$base.xml.XXXXXX)
chmod 644 $TMP_FILE && \
xsltproc --nodtdattr --novalid - $XKB_ROOT/rules/$base.xml <<- __END__ | \
awk 'NR > 1 { print h } { h = $0 } END { ORS = ""; print h }' > $TMP_FILE && \
mv -f $TMP_FILE $XKB_ROOT/rules/$base.xml || \
rm $TMP_FILE
<?xml version="1.0" ?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output encoding="UTF-8" doctype-system="xkb.dtd"/>
<xsl:template match="xkbConfigRegistry/optionList/group[configItem/name='keypad']">
  <xsl:copy>
    <xsl:apply-templates select="@*|node()"/>
    <xsl:text disable-output-escaping="yes"><![CDATA[  <option>
        <configItem>
          <name>keypad:atm</name>
          <description>ATM/phone-style keypad.</description>
        </configItem>
      </option>
    ]]></xsl:text>
  </xsl:copy>
</xsl:template>
<xsl:template match="/ | @* | node() ">
  <xsl:copy><xsl:apply-templates select="@* | node()" /></xsl:copy>
</xsl:template>
</xsl:stylesheet>
__END__
fi

COUNT=$(grep -c "<name>kpdl:semi</name>" $XKB_ROOT/rules/$base.xml) || true
if [ $COUNT -eq 0 ]; then
TMP_FILE=$(mktemp $XKB_ROOT/rules/$base.xml.XXXXXX)
chmod 644 $TMP_FILE && \
xsltproc --nodtdattr --novalid - $XKB_ROOT/rules/$base.xml <<- __END__ | \
awk 'NR > 1 { print h } { h = $0 } END { ORS = ""; print h }' > $TMP_FILE && \
mv -f $TMP_FILE $XKB_ROOT/rules/$base.xml || \
rm $TMP_FILE
<?xml version="1.0" ?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output encoding="UTF-8" doctype-system="xkb.dtd"/>
<xsl:template match="xkbConfigRegistry/optionList/group[configItem/name='kpdl']">
  <xsl:copy>
    <xsl:apply-templates select="@*|node()"/>
    <xsl:text disable-output-escaping="yes"><![CDATA[  <option>
        <configItem>
          <name>kpdl:semi</name>
          <description>Dot, with semi-colon on third-level</description>
        </configItem>
      </option>
    ]]></xsl:text>
  </xsl:copy>
</xsl:template>
<xsl:template match="/ | @* | node() ">
  <xsl:copy><xsl:apply-templates select="@* | node()" /></xsl:copy>
</xsl:template>
</xsl:stylesheet>
__END__
fi

COUNT=$(grep -c "<name>compose:102</name>" $XKB_ROOT/rules/$base.xml) || true
if [ $COUNT -eq 0 ]; then
TMP_FILE=$(mktemp $XKB_ROOT/rules/$base.xml.XXXXXX)
chmod 644 $TMP_FILE && \
xsltproc --nodtdattr --novalid - $XKB_ROOT/rules/$base.xml <<- __END__ | \
awk 'NR > 1 { print h } { h = $0 } END { ORS = ""; print h }' > $TMP_FILE && \
mv -f $TMP_FILE $XKB_ROOT/rules/$base.xml || \
rm $TMP_FILE
<?xml version="1.0" ?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output encoding="UTF-8" doctype-system="xkb.dtd"/>
<xsl:template match="xkbConfigRegistry/optionList/group[configItem/name='Compose key']">
  <xsl:copy>
    <xsl:apply-templates select="@*|node()"/>
    <xsl:text disable-output-escaping="yes"><![CDATA[  <option>
        <configItem>
          <name>compose:102</name>
          <description>Less-than/greater-than is Compose.</description>
        </configItem>
      </option>
    ]]></xsl:text>
  </xsl:copy>
</xsl:template>
<xsl:template match="/ | @* | node() ">
  <xsl:copy><xsl:apply-templates select="@* | node()" /></xsl:copy>
</xsl:template>
</xsl:stylesheet>
__END__
fi

done # bases

# append an inclusion to the relevant files. the data itself is
# stored in separate files so that removal is easier for the scripts.
grep -c 'xkb_types[\ \t]*"shift3"' $XKB_ROOT/types/numpad 1>/dev/null || \
cat <<- __END__ >> $XKB_ROOT/types/numpad
partial xkb_types "shift3" { include "shift3" };
__END__

grep -c 'xkb_symbols[\ \t]*"102"' $XKB_ROOT/symbols/compose 1>/dev/null || \
cat <<- __END__ >> $XKB_ROOT/symbols/compose
partial modifier_keys xkb_symbols "102" { include "102" };
__END__

grep -c 'xkb_symbols[\ \t]*"dvp"' $XKB_ROOT/symbols/us 1>/dev/null || \
cat <<- __END__ >> $XKB_ROOT/symbols/us
partial alphanumeric_keys xkb_symbols "dvp" { include "dvp" };
__END__

grep -c 'xkb_symbols[\ \t]*"ops"' $XKB_ROOT/symbols/keypad 1>/dev/null || \
cat <<- __END__ >> $XKB_ROOT/symbols/keypad
partial keypad_keys xkb_symbols "ops" { include "ops" };
__END__

grep -c 'xkb_symbols[\ \t]*"hex"' $XKB_ROOT/symbols/keypad 1>/dev/null || \
cat <<- __END__ >> $XKB_ROOT/symbols/keypad
partial keypad_keys xkb_symbols "hex" { include "hex" };
__END__

grep -c 'xkb_symbols[\ \t]*"atm"' $XKB_ROOT/symbols/keypad 1>/dev/null || \
cat <<- __END__ >> $XKB_ROOT/symbols/keypad
partial keypad_keys xkb_symbols "atm" { include "atm" };
__END__

grep -c 'xkb_symbols[\ \t]*"semi"' $XKB_ROOT/symbols/kpdl 1>/dev/null || \
cat <<- __END__ >> $XKB_ROOT/symbols/kpdl
partial keypad_keys xkb_symbols "semi" { include "semi" };
__END__
