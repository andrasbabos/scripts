## pxe gen - pxe boot menu generator

This script generate a pxe boot menu for network install/boot of servers on Linux, UNIX type operating systems.
The script only generate the boot menu file it doesnt depend tftp,dhcp services and it doesn't check their existence.
I tested and use it on CentOS 7 and Mac OS X systems.

### how to use

Copy the files to a subdirectory then modify the variables in the pxe_gen.sh to reflect the actual state. The CONF_ROOT is the directory where the config files are (so you can put the script somewhere else), and the PXE_fILE is the target menu file, it's location depends on the used os.

Optionally modify the header.txt it's the static head of the menu file.

Fill the pxe.csv with useful data then run the script, it will rename the current menu file and create a new one.

### pxe.csv structure

The columns of the file:
* n - in case the value is y then the menu entry will be generated, any other case it didn't. Simply replace y with n to mark the entries you don't want to use.
* group - menu entries grouped together like Ubuntu or ESXi. If you don't want to use this feature then simply use the same name for every entry.
* label - boot entry name it's working without the graphical menu, one word without spaces.
* menu_label - this is the menu.c32 specific label it can be a whole sentence to describe the entry.
* kernel - the kernel to boot, you can see some examples in the example file.
* append - the options which needed for the entry.
