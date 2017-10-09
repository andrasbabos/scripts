#!/bin/bash

#vm
if [ `hostname` == "centos.example.com" ]; then
  DISK="/dev/sdb"
  PARTITION="/dev/sdb1"
  CUSTOM_FILES="/mnt/hgfs/andrasb/Ericsson/repok/multiboot_pendrive/pendrive_root"
  ISO_ROOT_DIR="/mnt/hgfs/andrasb/iso_root"
  SYSLINUX_DIR="/usr/share/syslinux"
#labor desktop computer
elif [ `hostname` == "andras.example.com" ]; then
  DISK="/dev/sdc"
  PARTITION="/dev/sdc1"
  CUSTOM_FILES="/srv/storage/multiboot_pendrive"
  ISO_ROOT_DIR="/srv/storage/iso_root"
  SYSLINUX_DIR="/usr/share/syslinux"
else
  echo "No configuration found for this hostname, exiting now."
  exit 1
fi

USB_MOUNT_DIR="/mnt/pendrive"
ISO_MOUNT_DIR="/mnt/iso"
ALL_YES="n"
INPUT="n"

function read_input ()
{
  if [ $ALL_YES == "y" ]; then
    INPUT="y"
    echo "### all yes pressed ###"
  else
    read -n 1 INPUT </dev/tty
  fi

  if [ -n "$INPUT" ] && [ $INPUT == "a" ]; then
    ALL_YES="y"
    INPUT="y"
  fi
}

if [ `whoami` != "root" ]; then
  echo "Please run the script as root!"
  exit 1
fi

if [ ! -d "$USB_MOUNT_DIR" ]; then
  echo "### Creating directory: $USB_MOUNT_DIR ###"
  mkdir $USB_MOUNT_DIR
fi

if [ ! -d "$ISO_MOUNT_DIR" ]; then
  echo "### Creating directory: $ISO_MOUNT_DIR ###"
  mkdir $ISO_MOUNT_DIR
fi

echo "### Partition, format pendrive (y/a/N)? ###"
read_input
echo
if [ -n "$INPUT" ] && [ $INPUT == "y" ]; then
  #install-mbr $DISK  -- only on Debian/Ubuntu
  dd bs=440 count=1 conv=notrunc if=$SYSLINUX_DIR/mbr.bin of=$DISK
  cat $CUSTOM_FILES/partition_table.txt | sfdisk $DISK
  mkdosfs $PARTITION
  syslinux $PARTITION
fi

mount -t vfat $PARTITION $USB_MOUNT_DIR

echo "### Install boot menu files (y/a/N)? ###"
read_input
echo
if [ -n "$INPUT" ] && [ $INPUT == "y" ]; then
  mkdir -p $USB_MOUNT_DIR/syslinux
  cp $SYSLINUX_DIR/menu.c32 $USB_MOUNT_DIR/syslinux/
  cp $SYSLINUX_DIR/chain.c32 $USB_MOUNT_DIR/syslinux/
#  cp $CUSTOM_FILES/syslinux/syslinux.cfg $USB_MOUNT_DIR/syslinux/
  cp $CUSTOM_FILES/syslinux/boot.msg $USB_MOUNT_DIR/syslinux/

#syslinux.cfg generation
  OLDIFS="$IFS"
  IFS=$'\n'
  declare -a PXE_MENU_GROUPS=( `cat $CUSTOM_FILES/items.txt | cut -d\; -f6 | uniq` )
  IFS="$OLDIFS"
  unset PXE_MENU_GROUPS[0]

#header
  cat $CUSTOM_FILES/syslinux/syslinux.cfg.head > $USB_MOUNT_DIR/syslinux/syslinux.cfg

#group
  for PXE_MENU_GROUP in "${PXE_MENU_GROUPS[@]}"; do
#group header
    echo "MENU BEGIN $PXE_MENU_GROUP..." >> $USB_MOUNT_DIR/syslinux/syslinux.cfg

#group body
    while IFS=';' read -ra LINE; do
      YN=${LINE[0]}
      GROUP_ELEM=${LINE[5]}
      LABEL=${LINE[6]}
      MENU_LABEL=${LINE[7]}
      KERNEL=${LINE[8]}
      APPEND=${LINE[9]}
      if [ "$YN" == "y" ] && [ "$PXE_MENU_GROUP" == "$GROUP_ELEM" ]; then
        echo "    LABEL $LABEL" >> $USB_MOUNT_DIR/syslinux/syslinux.cfg
        echo "        MENU LABEL $MENU_LABEL" >> $USB_MOUNT_DIR/syslinux/syslinux.cfg
        echo "        KERNEL $KERNEL" >> $USB_MOUNT_DIR/syslinux/syslinux.cfg
        if [ "$APPEND" != " " ]; then
          echo "        APPEND $APPEND" >> $USB_MOUNT_DIR/syslinux/syslinux.cfg
        fi
      fi
    done < $CUSTOM_FILES/items.txt
#group body end
    echo "    LABEL Back to root menu" >> $USB_MOUNT_DIR/syslinux/syslinux.cfg
    echo "        MENU EXIT" >> $USB_MOUNT_DIR/syslinux/syslinux.cfg
    echo "MENU END" >> $USB_MOUNT_DIR/syslinux/syslinux.cfg
  done

#header end
    cat $CUSTOM_FILES/syslinux/syslinux.cfg.tail >> $USB_MOUNT_DIR/syslinux/syslinux.cfg
fi

#tools
echo "### Install tools files (memory test, sysrescd, etc.) (y/a/N)? ###"
read_input
echo
if [ -n "$INPUT" ] && [ $INPUT == "y" ]; then
  while IFS=';' read -ra LINE; do
    YN=${LINE[0]}
    TYPE=${LINE[1]}
    SUBDIR=${LINE[3]}
    ISO_PATH=${LINE[4]}
    if [ "$YN" == "y" ] && [ "$TYPE" == "sysrescd" ] && [ "$SUBDIR" != " " ]; then
      mount -o loop,ro "$ISO_ROOT_DIR$ISO_PATH" $ISO_MOUNT_DIR
      mkdir -p $USB_MOUNT_DIR/tools $USB_MOUNT_DIR/tools/sysrescd $USB_MOUNT_DIR/tools/memtest $USB_MOUNT_DIR/tools/dban
      cp $ISO_MOUNT_DIR/bootdisk/dban.bzi $USB_MOUNT_DIR/tools/dban/
      cp $ISO_MOUNT_DIR/bootdisk/memtestp $USB_MOUNT_DIR/tools/memtest/
      #the sysrcd.dat needed directly in the pendrive root
      cp $ISO_MOUNT_DIR/sysrcd.dat $USB_MOUNT_DIR/
      cp $ISO_MOUNT_DIR/isolinux/rescue32 $USB_MOUNT_DIR/tools/sysrescd/
      cp $ISO_MOUNT_DIR/isolinux/initram.igz $USB_MOUNT_DIR/tools/sysrescd/
      umount $ISO_MOUNT_DIR
      cp $CUSTOM_FILES/memtest/memtest86+.bin $USB_MOUNT_DIR/tools/memtest/memtest86+bin
    fi
  done < $CUSTOM_FILES/items.txt
fi

echo "### With unattended installation only one ubuntu iso can be present on the pendrive! ###"
echo
while IFS=';' read -ra LINE; do
  YN=${LINE[0]}
  TYPE=${LINE[1]}
  NAME=${LINE[2]}
  SUBDIR=${LINE[3]}
  ISO_PATH=${LINE[4]}
  if [ "$YN" == "y" ] && [ "$TYPE" == "ubuntu" ] && [ "$SUBDIR" != " " ]; then
    echo "### Install $NAME (y/a/N) ###"
    read_input
    echo
    if [ -n "$INPUT" ] && [ $INPUT == "y" ]; then
      mkdir -p $USB_MOUNT_DIR/ubuntu/$SUBDIR/server/hdmedia
      mkdir -p $USB_MOUNT_DIR/ubuntu/$SUBDIR/preseed
      cp $ISO_ROOT_DIR/Ubuntu/hdmedia_kernel/$SUBDIR/vmlinuz $USB_MOUNT_DIR/ubuntu/$SUBDIR/server/hdmedia/
      cp $ISO_ROOT_DIR/Ubuntu/hdmedia_kernel/$SUBDIR/initrd.gz $USB_MOUNT_DIR/ubuntu/$SUBDIR/server/hdmedia/
      cp "$ISO_ROOT_DIR$ISO_PATH" $USB_MOUNT_DIR/
      mount -o loop,ro "$ISO_ROOT_DIR$ISO_PATH" $ISO_MOUNT_DIR
      #ubuntu-server.seed needed for standard install
      cp $ISO_MOUNT_DIR/preseed/ubuntu-server.seed $USB_MOUNT_DIR/ubuntu/$SUBDIR/preseed/
      #use 12.04 files at the moment
      cp $CUSTOM_FILES/ubuntu/$SUBDIR/preseed/* $USB_MOUNT_DIR/ubuntu/$SUBDIR/preseed/
      umount $ISO_MOUNT_DIR
    fi
  fi
done < $CUSTOM_FILES/items.txt

# copy general esxi files
echo "### Copy ESXi kickstart files (y/a/N) ###"
read_input
echo
if [ -n "$INPUT" ] && [ $INPUT == "y" ]; then
  mkdir -p $USB_MOUNT_DIR/esx/kickstart
  cp -r $CUSTOM_FILES/esx/kickstart/* $USB_MOUNT_DIR/esx/kickstart/
fi

#esxi loop
while IFS=';' read -ra LINE; do
  YN=${LINE[0]}
  TYPE=${LINE[1]}
  NAME=${LINE[2]}
  SUBDIR=${LINE[3]}
  ISO_PATH=${LINE[4]}
  if [ "$YN" == "y" ] && [ "$TYPE" == "esxi" ] && [ "$SUBDIR" != " " ]; then
    echo "### Install $NAME (y/a/N) ###"
    read_input
    echo
    if [ -n "$INPUT" ] && [ $INPUT == "y" ]; then
      mkdir -p $USB_MOUNT_DIR/esx/$SUBDIR
      cp $CUSTOM_FILES/esx/$SUBDIR/* $USB_MOUNT_DIR/esx/$SUBDIR/
      mount -o loop,ro "$ISO_ROOT_DIR$ISO_PATH" $ISO_MOUNT_DIR
      cp -r $ISO_MOUNT_DIR/* $USB_MOUNT_DIR/esx/$SUBDIR/
      umount $ISO_MOUNT_DIR
    fi
  fi

done < $CUSTOM_FILES/items.txt

# copy general sles files
echo "### Copy SLES kickstart files (y/a/N) ###"
read_input
echo
if [ -n "$INPUT" ] && [ $INPUT == "y" ]; then
  mkdir -p $USB_MOUNT_DIR/sles/kickstart
  cp -r $CUSTOM_FILES/sles/kickstart/* $USB_MOUNT_DIR/sles/kickstart/
fi

#SLES loop
while IFS=';' read -ra LINE; do
  YN=${LINE[0]}
  TYPE=${LINE[1]}
  NAME=${LINE[2]}
  SUBDIR=${LINE[3]}
  ISO_PATH=${LINE[4]}
  if [ "$YN" == "y" ] && [ "$TYPE" == "sles" ] && [ "$SUBDIR" != " " ]; then
    echo "### Install $NAME (y/a/N) ###"
    read_input
    echo
    if [ -n "$INPUT" ] && [ $INPUT == "y" ]; then
      mkdir -p $USB_MOUNT_DIR/sles/$SUBDIR
            mount -o loop,ro "$ISO_ROOT_DIR$ISO_PATH" $ISO_MOUNT_DIR
      cp -r $ISO_MOUNT_DIR/* $USB_MOUNT_DIR/sles/$SUBDIR/
      umount $ISO_MOUNT_DIR
    fi
  fi
done < $CUSTOM_FILES/items.txt

umount $USB_MOUNT_DIR
