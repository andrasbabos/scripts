## d update - dns and dhcp config file generator script
This script generate dhcp (isc-dhcp-server) and dns (named) configuration files from templates and csv file then restart the services.

It's tested on Mac OS X and CentOS 7.

### how to use
You will need to install bind and isc-dhcp-server packages for your system, copy the files from the git repository to the server.

Before first time check and modify the following files, the original config files will be overwritten by the templates.

templates
* named.conf.head - forwarders and allow-query entries
* dhcpd.conf.head - fill with your network ranges and neccessary configuration. Delete the vmware range if you don't need it, it's used to give temporary address for new or disposable virtual machines.
* the dns forward and revers files - example.com.head and 10.0.0.1.db.head are examples, rename these to your own network names and modify to your system.

d_update.csv - this is the main data file for the hosts, the columns of the csv file:
* n - y/n value, in case of yes, the entry will be generated to the config files, otherwise it's skipped
* name - host part of the fqdn
* domain - domain part of the fqdn, it's used for the dns forward zone file name also
* network - network part of the ip address it's used in the reverse zone file name also
* host - this is the host part of the ip address
* MAC address - this address is only needed for hosts who have static ip address assigned via dhcp, for simple dns entries it's unneccesary

d_update.sh

You need to modify the beginning of the main script it decide what variables to use based on the hostname, the first entry is CentOS 7 the second is Msc OS X with macports.
* CONF_ROOT the directory where all the templates and csv are
* SYS_ROOT the root folder on the file system from where /etc directory present, if you use the system packages then it's /etc and sys_root is empty, if you use /usr/local then sys root is /usr/local
* SERVICE the type of service management to restart bind, dhcp server. the current supported are systemd (centos 7) and launchd for macports, you can easily modify to others

After these modifications simply run d_update.sh and the script will generate new config files then restart services.
