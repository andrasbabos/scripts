#!/usr/bin/expect
set HOSTNAME [lindex $argv 0];
set USERNAME [lindex $argv 1];
set PASSWORD [lindex $argv 2];
set TFTP_HOST [lindex $argv 3];
set TFTP_DIR [lindex $argv 4];

if { $PASSWORD == "none" } {
   set PASSWORD ""
}

spawn telnet $HOSTNAME
expect "User:"
send "$USERNAME\r"
expect "Password:"
send "$PASSWORD\r"
expect " >"
send "ena\r"
expect "Password:"
send "\r"
expect " #"
send "terminal length 0\r"
log_file $TFTP_DIR/$HOSTNAME.cfg;
send "show running-config\r"
send "logout\r"
expect "Would you like to save them now? (y/n)"
send "n\r"
log_file;
expect "Connection closed by foreign host."
exit 0

#copy binary file
#send "copy nvram:startup-config tftp://$TFTP_HOST/$HOSTNAME.cfg\r"
#expect "Are you sure you want to start? (y/n)"
#send "y\r"
#expect "File transfer operation completed successfully."
#send "logout\r"
#expect "Would you like to save them now? (y/n)"
#send "n\r"
#expect "Connection closed by foreign host."
