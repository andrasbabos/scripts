## short description

This is an ansible playbook to add a user to the linux server which have the security requirement that service users don't have general shell only command execution via ssh login.

To circumvent the sshd_config's one user - one command policy the command is a python script which accepts any command as input parameter, compare it with a predefined list of commands and if it's whitelisted then it will run it.

The purpose of this script is to copy a system file like /etc/hosts to a target server via rsync with a regular service user then copy the file to the target directory with sudo permissions to preserve the root only rights on the target file. These are multiple commands and one user can execute it via the whitelist.

It's goal is to modify an existing script in place which uses root user to log in to other servers and copy system files, the final goal is to replace root with a restricted service user.

## how to use

Copy the variable from the defaults/main.yml and replace with proper values.

* sudo_file - name of the file on the target server's /etc/sudoers.d
* sudo_command - commands which will be available via sudo, these needs to be defined in the whitelist also
* whitelist_command - commands which will be available on the target server via ssh

Create ansible group "restricted_user" and all your related hosts.

Run the playbook:

    ansible-playbook restricted_user.yml

The default values create following configuration files:

/etc/sudoers.d/restricteduser

    #managed by restricted_user ansible role
    restricteduser  ALL=(ALL)  NOPASSWD: /bin/ls, /bin/more

/usr/local/etc/restricted_user/restricteduser.txt

    #managed by restricted_user ansible role
    /bin/ls
    /bin/more

append to /etc/ssh/sshd_config

    # BEGIN Managed by restricted_user ansible role
    Match User restricteduser
        AllowTCPForwarding no
        X11Forwarding no
        ForceCommand /usr/local/bin/command_whitelist.py
    # END Managed by restricted_user ansible role
