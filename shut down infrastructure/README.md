## shut down VMware infrastructure

The purpose of this Powershell script is to shut down virtual machines and ESXi hosts in order (eg. vm's, vcenter, hosts).
I wrote this myself but i found a more well-rounded script for the same purpose: https://myvirtualife.net/2014/07/14/powershell-script-for-shutting-down-your-vsphere-environment/
I recommend to check it out also!

### how to use

You will need to modify the variables at the beginning of the script, the vcenter variable is the FQDN of the vm it's needed for the powercli connection and the vcentervmname is the name of the virtual machine, it's needed to shut down the vm on the ESXi host.

The script run in the following steps:

1. Graceful shut down all vm's with VMware tools and force power off the others except the vcenter.
2. Give a list of still powered on vm's, these need manual power off from the user.
3. Shut down ESXi hosts except the one where the vcenter still run.
4. Connect to the remaining ESXi host shut down the vcenter vm on it then shut down the host.
