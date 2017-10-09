#!/usr/bin/expect
set timeout 20
set HOSTNAME [lindex $argv 0];
set USERNAME [lindex $argv 1];
set PASSWORD [lindex $argv 2];
set TFTP_HOST [lindex $argv 3];

if { $PASSWORD == "none" } {
   set PASSWORD ""
}

#old extreme os
set PARAMETER ""

spawn telnet $HOSTNAME
expect "login:"
send "$USERNAME\r"
expect "password:"
send "$PASSWORD\r"
expect "1 #"
#send "disable clipaging\r"
#log_file $name.txt
send "upload configuration $TFTP_HOST $HOSTNAME.cfg $PARAMETER\r"
expect "2 #"
#send "show configuration\r"
#expect ".3 #"
send "exit\r"
expect "Connection closed by foreign host."
#log_file
