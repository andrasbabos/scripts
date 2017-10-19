## multiboot pendrive

This script will put various operating system installations and useful bootable system tools on one pendrive with menu.

### how to use

#### modify script
The script is tested on centos 7, most likely it will need modification at partitioning/syslinux part for other os.

Check the reinstall_pendrive.sh modify the beginning for your hostname or delete all the if cases and simply preserve one set of variables, then fill these with proper values for your system.

* DISK the device path/name of the pendrive
* CUSTOM_FILES  the full path to the pendrive_root directory from the git repository
* PARTITION the partition to format on the pendrive
* ISO_ROOT_DIR  the root directory of the iso files (see below)
* SYSLINUX_DIR the directory where syslinux files present

#### gather pendrive data

The partition_table.txt is the output of "sfdisk -d /dev/sdc" output with the actual pendrive device name, you will need to replace it with your own. Simply make one fat32 partition on your pendrive, then save the table with sfdisk command then replace the text file. The script can repartition, reformat the pendrive to make sure it will work but it needs the proper data.

#### iso root directory

You will need to supply iso files of install media for various operating systems the script will use images to copy files needed to the pendrive.
This is my directory structure, you can do differently as you will need to give the full path to each important file in the items.txt.

    .
    ├── CentOS
    │   └── CentOS-7-x86_64-Everything-1611.iso
    ├── SuSE
    │   ├── SLES11
    │   │   ├── SLES-11-SP3-DVD-x86_64-GM-DVD1.iso
    │   │   └── SLES-11-SP4-DVD-x86_64-GM-DVD1.iso
    │   └── SLES12
    │       └── SLE-12-Server-DVD-x86_64-GM-DVD1.iso
    ├── systemrescuecd
    │   └── systemrescuecd-x86-4.0.0.iso
    ├── Ubuntu
    │   ├── hdmedia_kernel
    │   │   ├── 1404
    │   │   │   ├── initrd.gz
    │   │   │   └── vmlinuz
    │   └── ubuntu-14.04-server-amd64.iso
    └── VMware
        ├── VMware\ 6.0
        │   ├── VMware-ESXi-6.0.0-Update1-3073146-LNV-20151125.iso
        │   ├── VMware-ESXi-6.0.0-Update1-3380124-HPE-600.9.4.5.11-Jan2016.iso
        └── VMware\ 6.5
            └── VMware-ESXi-6.5.0-Update1-5969303-HPE-650.U1.10.1.0.14-Jul2017.iso

#### items.txt description

This it the "configuration database" the csv style file where all boot menu entries and images to install information are stored.
There are two different type of entries, the one where both the install media copy and boot menu entry is needed and the second where only boot menu entry will be generated. The cause of this to generate different boot options for the same install media like standard and kickstart install.

The columns are:
* n - y/n value, if yes, then the line is processed, it's an easy to understand way to comment the not needed lines
* type - internal type to decide how to process the line. like if the value is esxi then the line will be processed in the esxi part of the script
* name - this is a human friendly name the script will ask to install the $NAME during execution
* subdir - the entries with subdir will be processed as copy install media to pendrive, the subdir will be a directory on the pendrive where the files present, lines with subdir value " " are the boot menu only entries
* iso_path - the path of the iso file to use inside the tree, the path to the tree is the iso_root_dir
* group - this is an entry for menu.c32 based boot menu, the menu entries are in groups like all esxi 5.x entires are in esxi5, this is completely user defined
* label - this is an entry for the barebones, standard boot menu, these are the simple one word menu entries like "esxi600u3_kick"
* menu_label this is an entry for menu.c32 based boot menu, these are the human readable names for the entries like "ESXi 6.0.0 U3 kickstart install"
* kernel - kernel to boot
* append - paramaters to append to boot like initrd, kickstart file

#### kickstart files

You can find kickstart installation files for various operating systems in the github repo, i don't have detailed documentation how to use these, but all are written based on official documentation, tinkering, etc.

#### operating systems

These are the currently used operating systems and the tricks needed to use them in this solution:

sles: this doesn't have any special modification

esxi: the boot.cfg file is modified and renamed manually for each entry. The important changes are the "prefix=/somewhere" option and i removed the leading "/" from the module names, because the files aren't in the root of the pendrive, they're in a subdirectory.

ubuntu: the special hdmedia kernel is needed for the pendrive based boot it's available in the ubuntu http repositories and there can be only one ubuntu iso file on the pendrive otherwise the installer maybe use the wrong one. If the installer will drop an error after some steps and complaining about missing kernel modules on the install media then there is a hdmedia kernel - iso file mismatch.

systemrescuecd: this doesn't have any special modification

#### how to run

simply execute the script and it will go in an interactive way
