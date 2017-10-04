#!/bin/bash
# debug mode
# set -xv
CONF_ROOT="/Users/andrasb/git_repos/vlab/infrastruktura/scriptek/pxe_gen"
PXE_fILE="/opt/local/var/tftp-hpa/pxelinux.cfg/default"

if [[ $EUID -ne 0 ]]; then
 echo "This script must be run as root or with sudo";
 exit 1;
fi

# select file from command line or default
if [ $1 ] && [ -f "$1" ]; then
  INFILE="$1"
else
  INFILE="$CONF_ROOT/pxe.csv"
fi

declare -a MENU_GROUPS=( `cat $INFILE | cut -d, -f2 | uniq` )
unset MENU_GROUPS[0]

mv $PXE_fILE $PXE_fILE.`date +%F_%R`

#header
cat $CONF_ROOT/header.txt > $PXE_fILE

for MENU_GROUP in ${MENU_GROUPS[@]}; do
#group header
  echo "MENU BEGIN $MENU_GROUP..." >> $PXE_fILE

#group body
  while IFS=',' read -ra LINE; do
    YN=${LINE[0]}
    GROUP_ELEM=${LINE[1]}
    LABEL=${LINE[2]}
    MENU_LABEL=${LINE[3]}
    KERNEL=${LINE[4]}
    APPEND=${LINE[5]}
    if [ "$YN" == "y" ] && [ $MENU_GROUP == "$GROUP_ELEM" ] ; then
      echo "    LABEL $LABEL" >> $PXE_fILE
      echo "        MENU LABEL $MENU_LABEL" >> $PXE_fILE
      echo "        KERNEL $KERNEL" >> $PXE_fILE
      echo "        APPEND $APPEND" >> $PXE_fILE
    fi
  done < $INFILE

#group end
  echo "    LABEL Back to root menu" >> $PXE_fILE
  echo "        MENU EXIT" >> $PXE_fILE
  echo "MENU END" >> $PXE_fILE

done
