## ESXi shutdown
The purpose of this script is to efficiently shut down virtual machines on ESXi hosts and the hosts itself which have free ESXi license.

The free license doesn't allow any type of remote modification like shut down vm's and the workaround is to log in to the host with ssh and execute local commands.

### how to use
#### recommendations
First enable sshd service on the ESXi host via the c# or web client.

Then I recommend to use ssh keys to log into the hosts, there are good documentation about this on the internet.
The script will ask for password in each run, first it copy the script to the host and the second it will log in to the host to execute it, so it can

For the detailed help, commmand parameters simply run the script.

#### interactive mode

In interactive mode the script will copy itself to the host then execute it and you can select options in a text based menu.

Run the command:

    esxi_shutdown.sh -i -s esxi1.example.com

Menu example:

    1 - list running virtual machines
    2 - graceful shut down virtual machines with running vmware tools
    3 - hard power off all virtual machines
    4 - graceful shutdown esxi host if no running virtual machines present
    5 - graceful reboot esxi host if no running virtual machines present
    q - quit

#### unattended mode

In this mode you can send commands (like shut down vm's or reboot host) to the ESXi host, it's for scripted or copy-paste usage.

    esxi_shutdown.sh -s esxi1.example.com -c shutdownguest
    esxi_shutdown.sh -s esxi1.example.com -c rebootesxi
