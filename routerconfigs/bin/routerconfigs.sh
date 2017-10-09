#!/bin/bash
SCRIPT_ROOT="/home/Store/backup/routerconfigs"
source $SCRIPT_ROOT/etc/config

if [[ $DEBUG == "y" ]]; then
    set -xv
fi

if [ ! -d $SCRIPT_ROOT/archive/$TODAY ]; then
  mkdir $SCRIPT_ROOT/archive/$TODAY
fi

while IFS=';' read -ra LINE; do
    HOSTNAME=${LINE[0]}
    TYPE=${LINE[1]}
    USERNAME=${LINE[2]}
    PASSWORD=${LINE[3]}

    if [[ $HOSTNAME =~ ^# ]]; then
        continue 1
    elif [[ $TYPE == "extreme" || $TYPE == "extreme_log" || $TYPE == "extreme_old" || $TYPE == "cisco" || $TYPE == "juniper"  || $TYPE == "netgear" || $TYPE == "redback" ]]; then
        SCRIPT_NAME=$TYPE
    else
        echo "Wrong device type: " $TYPE
        continue 1
    fi

    echo "### Executing on:" $HOSTNAME "###"
    $SCRIPT_ROOT/bin/$SCRIPT_NAME.sh $HOSTNAME $USERNAME $PASSWORD $TFTP_HOST $TFTP_DIR

    cp $TFTP_DIR/$HOSTNAME.cfg $SCRIPT_ROOT/current/
    mv $TFTP_DIR/$HOSTNAME.cfg $SCRIPT_ROOT/archive/$TODAY/

	#The old Extreme switch put different date into every config so i delete it because it will be a separate config/commit in git where only the date differs.
    if [[ $HOSTNAME == "dev1.example.com" || $HOSTNAME == "dev2.example.com" || $HOSTNAME == "dev3.example.com" || $HOSTNAME == "dev4.example.com" || $HOSTNAME == "dev5.example.com" ]]; then
        grep -v "# Summit48si Configuration generated" $SCRIPT_ROOT/current/$HOSTNAME.cfg> $SCRIPT_ROOT/current/tempfile
        mv $SCRIPT_ROOT/current/tempfile $SCRIPT_ROOT/current/$HOSTNAME.cfg
    fi

done < $SCRIPT_ROOT/$ROUTER_LIST

cd $SCRIPT_ROOT/archive
zip -rm $TODAY.zip $TODAY

cd $SCRIPT_ROOT
git add .
git commit -a -m "cron `date +%F`"

exit 0
