#!/usr/bin/expect
#it will create config file dump instead of tfpt upload, it's needed where the device protected wih firewall because tftp needs port range

set timeout 20
set HOSTNAME [lindex $argv 0];
set USERNAME [lindex $argv 1];
set PASSWORD [lindex $argv 2];
set TFTP_HOST [lindex $argv 3];
set TFTP_DIR [lindex $argv 4];


if { $PASSWORD == "none" } {
   set PASSWORD ""
}

#old extreme os hack
if { $HOSTNAME == "dev1.example.com" || $HOSTNAME == "dev2.example.com" || $HOSTNAME == "dev3.example.com" } {
   set PARAMETER ""
} else {
   set PARAMETER "vr \"VR-Default\""
}

spawn telnet $HOSTNAME
expect "login:"
send "$USERNAME\r"
expect "password:"
send "$PASSWORD\r"
expect "1 #"
send "disable clipaging\r"
log_file $TFTP_DIR/$HOSTNAME.cfg
expect "2 #"
send "show configuration\r"
expect ".3 #"
send "exit\r"
expect "Connection closed by foreign host."
log_file
