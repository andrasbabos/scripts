#!/usr/bin/expect
set HOSTNAME [lindex $argv 0];
set USERNAME [lindex $argv 1];
set PASSWORD [lindex $argv 2];
set TFTP_HOST [lindex $argv 3]; 
set TFTP_DIR [lindex $argv 4];

spawn scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $USERNAME@$HOSTNAME:/config/juniper.conf.gz $TFTP_DIR/$HOSTNAME.cfg.gz
expect "password:"
send "$PASSWORD\r"
#expect 100%
expect eof

spawn gunzip -v $TFTP_DIR/$HOSTNAME.cfg.gz
expect "replaced with $HOSTNAME.cfg"

exit 0
