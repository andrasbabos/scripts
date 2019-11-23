## short description
These ansible roles are used to install BMC patrol agent, bladelogic agent and set up user for the discovery.

The provided install documentation is a lot manual work so I did some playbooks to automate the process. 

## how to use
### general

copy the group_vars/bmc_agent.yml to your group_vars directory then modify it for your needs.

Add your hosts to the bmc_agent group in your ansible inventory.

Run the full playbook

    ansible-playbook bootstrap_BMC.yml

or parts of it

    ansible-playbook bootstrap_BMC.yml -t bmc_patrol

In the documentation below I only mention the  variables, which most likely not straightforward to understand.

### bladelogic
The role will copy the installer rpm file to the target system, install/upgrade the rpm then delete it. The copy/delete will run every time, it will be better to host the rpm on  a shared directory or web server, but the current environment needs this method.

variables:
- bladelogic_copy_before/name - name of the rpm package
- source - directory on the ansible master host where the rpm and the config files are
- bladelogic_copy_after/name - config files which needs to be copied to the target system after installation

### discovery
The role will create the Linux user (discadmin), install sudo package, copy the proper /etc/sudoers.d/sudo_file.

variables:
- password: proper hashed password is needed like: 
- key: proper ssh key is needed like:

### patrol
This playbook will do the preprequisites, like copy install files, create patrol user, etc. The actual script run needs to be done manually because at the end we need to run a second script with unique path (generated from date, time, hostname), and it's too much work to make at safely executable.

The patrol agent installer needs to be downloaded from the Truesight Presentation server's package repository.

variables:
- patrol_source_dir - directory where the uncompressed installer is stored, the files will be copied to the target server's patrol_installer_dir
- patrol_installer_dir - directory on the target server to store the install media.
- patrol_target_dir - directory where the actual software will be installed, defined in the patrol agent installation media.
