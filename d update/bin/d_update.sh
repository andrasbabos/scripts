#!/bin/bash
# debug mode
# set -xv
HOST_NAME=`hostname`

if [ $HOST_NAME == "control.example.com" ]
then
    CONF_ROOT="/usr/local/etc/d_update"
    SYS_ROOT=""
    SERVICE="systemd"
elif [ $HOST_NAME == "macbook" ]
then
    CONF_ROOT="/Users/andrasb/git_repos/vlab/infrastruktura/scriptek/d_update/etc"
    SYS_ROOT="/opt/local"
    SERVICE="launchd"
else
  echo "Unknown hostname!"
  exit 2
fi

if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root or with sudo";
  exit 1;
fi

# select file from command line or default
if [ $1 ] && [ -f "$1" ]; then
  INFILE="$1"
else
  INFILE="$CONF_ROOT/d_update.csv"
fi

#dhcp
mv $SYS_ROOT/etc/dhcp/dhcpd.conf $SYS_ROOT/etc/dhcp/dhcpd.conf.`date +%F_%R`
cp $CONF_ROOT/dhcpd.conf.head $SYS_ROOT/etc/dhcp/dhcpd.conf

while IFS=',' read -ra LINE; do
  YN=${LINE[0]}
  NAME=${LINE[1]}
  NETWORK=${LINE[3]}
  HOST=${LINE[4]}
  MAC=${LINE[5]}
  if [ "$YN" == "y" ] && [ ! -z "$MAC" ] ; then
  echo "
  host $NAME {
      server-name "$NAME";
      hardware ethernet $MAC;
      fixed-address $NETWORK.$HOST;
  }" >> $SYS_ROOT/etc/dhcp/dhcpd.conf

  fi
done < $INFILE

cat $CONF_ROOT/dhcpd.conf.tail >> $SYS_ROOT/etc/dhcp/dhcpd.conf

if [ $SERVICE == "systemd" ]
then
    systemctl restart dhcpd
elif  [ $SERVICE == "launchd" ]
then
    port unload dhcp
    port load dhcp
    ps -ef | grep dhcp
fi

#dns
declare -a DOMAINS=( `cat $INFILE | cut -d, -f3 | uniq` )
#skip header line
unset DOMAINS[0]
declare -a REVDOMAINS=( `cat $INFILE | cut -d, -f4 | uniq` )
unset REVDOMAINS[0]
#serial number length is maximum 10 digit so i use only the last two digits from the year
AKT_DATE=`date +%y%m%d%H%M`

cp $CONF_ROOT/named.conf.head $SYS_ROOT/etc/named.conf

for FILE in ${DOMAINS[@]}; do
  [ -f $SYS_ROOT/var/named/$FILE ] && mv $SYS_ROOT/var/named/$FILE $SYS_ROOT/var/named/$FILE.`date +%F_%R`
  if  [ -f $CONF_ROOT/$FILE.head ]
  then
    cp $CONF_ROOT/$FILE.head $SYS_ROOT/var/named/$FILE
    sed -i.sedbackup "s/SERIAL_CHANGE/$AKT_DATE/g" $SYS_ROOT/var/named/$FILE
  else
    echo "head file: $FILE.head missing!"
  fi

  echo "
        zone \"$FILE\" IN {
                type master;
                file \"$FILE\";
                allow-update { none; };
        };
  " >> $SYS_ROOT/etc/named.conf

  while IFS=',' read -ra LINE; do
    YN=${LINE[0]}
    NAME=${LINE[1]}
    DOMAIN=${LINE[2]}
    NETWORK=${LINE[3]}
    HOST=${LINE[4]}
    if [ "$YN" == "y" ] && [ $DOMAIN == "$FILE" ] ; then
      echo "$NAME	IN A	$NETWORK.$HOST" >> $SYS_ROOT/var/named/$DOMAIN
    fi
  done < $INFILE
done

for FILE in ${REVDOMAINS[@]}; do
  [ -f $SYS_ROOT/var/named/$FILE.db ] && mv $SYS_ROOT/var/named/$FILE.db $SYS_ROOT/var/named/$FILE.db.`date +%F_%R`
  if [ -f $CONF_ROOT/$FILE.db.head ]
  then
    cp $CONF_ROOT/$FILE.db.head $SYS_ROOT/var/named/$FILE.db
    sed -i.sedbackup "s/SERIAL_CHANGE/$AKT_DATE/g" $SYS_ROOT/var/named/$FILE.db
  else
    echo "head file: $FILE.db.head missing!"
  fi

  REVFILE=`echo $FILE | awk -F "." '{ for (i=NF; i>1; i--) printf("%s.",$i); print $1; }'`
  echo "
        zone \"$REVFILE.in-addr.arpa\" IN {
                type master;
                file \"$FILE.db\";
                allow-update { none; };
        };
  " >> $SYS_ROOT/etc/named.conf

  while IFS=',' read -ra LINE; do
    YN=${LINE[0]}
    NAME=${LINE[1]}
    DOMAIN=${LINE[2]}
    NETWORK=${LINE[3]}
    HOST=${LINE[4]}
    if [ "$YN" == "y" ] && [ $NETWORK == "$FILE" ] ; then
      echo "$HOST	IN PTR	$NAME.$DOMAIN." >> $SYS_ROOT/var/named/$FILE.db
    fi
  done < $INFILE
done

cat $CONF_ROOT/named.conf.tail >> $SYS_ROOT/etc/named.conf

if [ $SERVICE == "systemd" ]
then
    systemctl restart named
elif  [ $SERVICE == "launchd" ]
then
    port unload bind9
    port load bind9
    ps -ef | grep named
fi
