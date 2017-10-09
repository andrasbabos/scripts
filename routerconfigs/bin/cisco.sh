#!/usr/bin/expect
set HOSTNAME [lindex $argv 0];
set USERNAME [lindex $argv 1];
set PASSWORD [lindex $argv 2];
set TFTP_HOST [lindex $argv 3];
set TFTP_DIR [lindex $argv 4];

spawn telnet $HOSTNAME 
expect ">" 
send "ena\r"
expect "Password:"
send "$PASSWORD\r"
expect "#"
send "copy running-config tftp://$TFTP_HOST/$HOSTNAME.cfg\r"
expect "Address or name"
send "\r"
expect "Destination filename"
send "\r"
expect "bytes/sec)"
send "logout\r"
expect "Connection closed by foreign host."
exit 0
