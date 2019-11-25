# scripts
Small scripts (bash, powershell, ansible) for system administration, written by me to help my daily job.

The projects, directories are:

* anisble playbooks
  * bootstrap bmc - install BMC patrol and bladelogic agents, set up service user for discovery on client servers
  * restricted user - create a user which can only execute one command via ssh login (security for service users)
  * dvdstore install - dell dvdstore install, web page with database for load testing
* truesight - bmc truesight operations management via rest api / powershell
  * compare - export devices from tsom, cmdb and merge these into one csv
  * manage - export, import truesight monitoring policies for the purpose of backup
* d update - dns, dhcp config generation and service reload
* multiboot pendrive - put various operating system installations and useful bootable system tools on one pendrive with menu
* pxe gen - pxe boot menu generator script
* routerconfigs - back up various router's configuration
* shut down infrastructure - shut down vSphere infrastructure
* esxi shutdown - shut down virtual machines and free licensed ESXi hosts
