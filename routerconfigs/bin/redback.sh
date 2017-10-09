#!/usr/bin/expect
set timeout 20
set HOSTNAME [lindex $argv 0];
set USERNAME [lindex $argv 1];
set PASSWORD [lindex $argv 2];
set TFTP_HOST [lindex $argv 3];

spawn telnet $HOSTNAME 
expect "login:" 
send "$USERNAME\r"
expect "Password:"
send "$PASSWORD\r"
expect "\[local\]*#"
send "save configuration tftp://$TFTP_HOST/$HOSTNAME.cfg\r"
expect "\[local\]*#"
send "exit\r"

