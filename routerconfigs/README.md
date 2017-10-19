## routerconfigs - router configuration backup

The purpose of this solution is to make configuration backups of various switch, router devices.

The script log in to the defined devices then get the configuration file (upload from device to tftp server, copy with scp, etc.) then store these in a git repository.

### how to use
Please check and modify the files mentioned in this readme file.

#### device scripts
there are shell/expect based scripts for each type of backup, like cisco, extreme, or extreme with config not tftp, etc. You can ran one of these in the following format:

    scriptname.sh device_hostname username password tftp_server
    extreme.sh extremesw01.example.com admin somepassword 10.0.10.10

The script are depend on telnet and expect to run commands on the device (except the juniper) so please try run the script toward your device and check if it's giving back the proper output. Expect depends on receiving a type of string like the prompt text and if it doesn't get the expected string then it will fail. If it doesn't work then you need to create your own expect part.

There is a general script, routerconfigs.sh it will parse the routers.txt for devices and execute the proper scripts one by one, then it will zip the configs and move these to the git repository.
This script needs to run on the tftp server and it stores all data in one git repository eg. both the scripts and the device configs. It's not ideal but it was the best way when it was developed.

To use the script, fill the config and routers.txt then the SCRIPT_ROOT variable in the routerconfigs.sh and then simply run the script.

#### config file
config - please modify the included variables, it's pretty straightforward, you need to provide the tftp server yourself

#### router inventory
routers.txt file contains the devices with parameters to parse

* hostname - fqdn, or ip address, it's needed for the script to reach the device
* type - the name of the script to use without the .sh
* user - username on device
* password - password for device
* comment - it's not used by the script it's for the user to have a place for comments
