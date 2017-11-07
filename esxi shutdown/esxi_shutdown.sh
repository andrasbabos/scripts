#!/bin/sh
#variables
scp_opts="-o ConnectTimeout=10 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
ssh_opts="-t -o ConnectTimeout=10 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
cmd_listvm="esxcli vm process list | grep Display | cut -f2 -d\:"
cmd_listguest='for i in `vim-cmd vmsvc/getallvms |tail -n +2 | egrep ^[[:digit:]] |cut -d " " -f 1`; do vim-cmd vmsvc/get.guest $i | grep -q guestToolsRunning; if [ $? -eq 0 ]; then vim-cmd vmsvc/get.summary $i | grep name | cut -f2 -d\"; fi ; done'
cmd_shutdownguest='for i in `vim-cmd vmsvc/getallvms |tail -n +2 | egrep ^[[:digit:]] |cut -d " " -f 1`; do vim-cmd vmsvc/get.guest $i | grep -q guestToolsRunning; if [ $? -eq 0 ]; then vim-cmd vmsvc/get.summary $i | grep name | cut -f2 -d\"; vim-cmd vmsvc/power.shutdown $i; fi ; done'
cmd_poweroffvm='for i in `esxcli vm process list | grep Display | cut -f2 -d\:`; do vim-cmd vmsvc/getallvms | egrep ^[[:digit:]] | grep $i |cut -d " " -f 1 | xargs vim-cmd vmsvc/power.off; done'
#sh doesn't support arrays
#cmd_shutdownesxi=('esxcli system maintenanceMode set -e true -t 0;' 'esxcli system shutdown poweroff -d 10 -r "Shell initiated system shutdown";' 'esxcli system maintenanceMode set -e false -t 0')
#cmd_rebootesxi=('esxcli system maintenanceMode set -e true -t 0;' 'esxcli system shutdown reboot -d 10 -r "Shell initiated system reboot";' 'esxcli system maintenanceMode set -e false -t 0')
cmd_shutdownesxi0="esxcli system maintenanceMode set -e true -t 0;"
cmd_shutdownesxi1='esxcli system shutdown poweroff -d 10 -r "Shell initiated system shutdown";'
cmd_shutdownesxi2="esxcli system maintenanceMode set -e false -t 0"
cmd_rebootesxi0="esxcli system maintenanceMode set -e true -t 0;"
cmd_rebootesxi1='esxcli system shutdown reboot -d 10 -r "Shell initiated system reboot";'
cmd_rebootesxi2="esxcli system maintenanceMode set -e false -t 0"
server_name="localhost"
run_command="none"
input="n"

#functions
setScriptPath()
{
  script_path=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
  script_name="$(basename "$0")"
}

copyToEsxi()
{
  echo "## scp script to $server_name ##"
  scp $scp_opts "$script_path/$script_name" root@$server_name:/tmp/
}

runRemotely()
{
  echo "## run script on $server_name via ssh ##"
  ssh $ssh_opts root@$server_name "/tmp/$script_name -i"
}

runScripted()
{
  case $run_command in
      listvm )           cmd_esxi=$cmd_listvm
                         ;;
      listguest )        cmd_esxi=$cmd_listguest
                         ;;
      shutdownguest )    cmd_esxi=$cmd_shutdownguest
                         ;;
      poweroffvm )       cmd_esxi=$cmd_poweroffvm
                         ;;
      shutdownesxi )     cmd_esxi=$cmd_shutdownesxi0$cmd_shutdownesxi1$cmd_shutdownesxi2
                         ;;
      rebootesxi )       cmd_esxi=$cmd_rebootesxi0$cmd_rebootesxi1$cmd_rebootesxi2
  esac

  if [ "$server_name" != "localhost" ]
  then
    cmd_final="ssh $ssh_opts root@$server_name '$cmd_esxi'"
  else
    cmd_final=$cmd_esxi
  fi
  eval $cmd_final
}

listVm()
{
  echo
  echo "  ## list all running vm's ##"
  eval $cmd_listvm
  echo "  ## list running vm's with vmware tools, these can be gracefully shut down ##"
  eval $cmd_listguest
}

shutdownGuest()
{
  echo
  echo "  ## graceful shut down virtual machines with running vmware tools ##"
  eval $cmd_shutdownguest
}

powerOffVm()
{
  echo
  echo "  ## hard power off all virtual machines ##"
  eval $cmd_poweroffvm
}

shutdownEsxi()
{
  echo
  echo "  ## enter maintenance mode ##"
  eval $cmd_shutdownesxi0
  echo "  ## shut down ##"
  eval $cmd_shutdownesxi1
  echo "  ## exit maintenance mode ##"
  eval $cmd_shutdownesxi2
  exit 0
}

rebootEsxi()
{
  echo
  echo "  ## enter maintenance mode ##"
  eval $cmd_rebootesxi0
  echo "  ## reboot ##"
  eval $cmd_rebootesxi1
  echo "  ## exit maintenance mode ##"
  eval $cmd_rebootesxi2
  exit 0
}

interactive()
{
  if [ `uname` != "VMkernel" ];
  then
    echo "This server doesn't look like an ESXi host."
    echo "Please run $0 -h for help."
    exit 1
  fi

  while [ "$input" != "q" ];
  do
    cat << EOF

  ## interactive menu ##
  1 - list running virtual machines
  2 - graceful shut down virtual machines with running vmware tools
  3 - hard power off all virtual machines
  4 - graceful shutdown esxi host if no running virtual machines present
  5 - graceful reboot esxi host if no running virtual machines present
  q - quit

EOF
    read -n 1 input
    case $input in
        1) listVm ;;
        2) shutdownGuest ;;
        3) powerOffVm ;;
        4) shutdownEsxi ;;
        5) rebootEsxi ;;
        6) exit 0
    esac
  done
}

help()
  {
    cat << EOF
    ESXi node shutdown script for standalone nodes, please enable ssh login on the target host before using this script.
    The script is using ssh to execute local commands on ESXi host which have free license activated.

    usage:
    esxi_shutdown.sh -i                       - run in interactive mode on local server
    esxi_shutdown.sh -i -s hostname           - copy script to target server, log in and run in interactive mode
    esxi_shutdown.sh -s hostname -c command   - log in to target server and execute command (for scripts)

    -i | -- interactive
    -v | --verbose           enable debug mode for the script
    -s | --server            server name (default is localhost)
    -c | --command command   execute one of the following commands: listvm, shutdownguest, poweroffvm, shutdownesxi, rebootesxi
    -h | --help              this help text

    Commands:
    listvm        -  list running virtual machines
    listguest     -  list running virtual machines with vmware tools
    shutdownguest -  graceful shut down virtual machines with running vmware tools
    poweroffvm    -  hard power off all virtual machines
    shutdownesxi  -  graceful shutdown esxi host if no running virtual machines present
    rebootesxi    -  graceful reboot esxi host if no running virtual machines present

    In case of questions, please contact Andras Babos
EOF
  }

if [ $# -eq 0 ]; then
  help
  exit 0
fi

while [ "$1" != "" ]; do
    case $1 in
        -v | --verbose )        set -xv;;
        -s | --server )         shift
                                server_name=$1;;
        -i | --interactive )    run_command="interactive";;
        -c | --command )        shift
                                run_command=$1;;
        -h | --help )           help
                                exit 0;;
        * )                     help
                                exit 1
    esac
    shift
done

#main
if [ "$server_name" = "localhost" ] && [ "$run_command" = "interactive" ]
then
  interactive

elif [ "$server_name" != "localhost" ] && [ "$run_command" = "interactive" ]
then
  setScriptPath
  copyToEsxi
  runRemotely

elif [ "$run_command" = "listvm" ] || [ "$run_command" = "listguest" ] || [ "$run_command" = "shutdownguest" ] || [ "$run_command" = "poweroffvm" ] || [ "$run_command" = "shutdownesxi" ] || [ "$run_command" = "rebootesxi" ]
then
  runScripted
else
  echo "Something bad in script execution."
  echo "Please run $0 -h for help."
  exit 1
fi
