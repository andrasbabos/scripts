#variables, fill in before execute
$vcenter = "vcenter.example.com"
$vCenterVMName = "vcenter"

#script part
Connect-VIServer -Server $vcenter
#Connect-VIServer -Server $vcenter -user administrator -password enteryourpasswordthere

$vCenterHost = (Get-VM $vCenterVMName).VMHost.Name

#gather all vm and shut them off
$poweredOnVm = Get-VM | where-object {$_.PowerState -eq "PoweredOn"}

ForEach ( $vm in $poweredOnVm )
{
    if ($vm.Name -ne $vCenterVMName)
    {
        $guestInfo = get-view -Id $vm.ID
        if ($guestInfo.config.Tools.ToolsVersion -eq 0)
        {
            Stop-VM $vm -confirm:$false | out-null
        }
        else
        {
           Stop-VMGuest $vm -Confirm:$false | out-null
        }
    }
}

#list about the still running vm's these needs manual shutdown
Write-Host "waiting for guest shutdowns"
sleep 12
Write-Host "running vm's:"
Get-VM | where-object {$_.PowerState -eq "PoweredOn"} | Select Name

Read-Host -Prompt "Please press enter when you stopeed all vm's except vcenter and it's safe to shut down hosts."

#shut down esxi hosts
get-VMHost | where-object {$_.name -ne $vCenterHost} | Stop-VMHost -force:$true -runasync:$true -confirm:$false | out-null

Disconnect-VIServer -Server $vcenter -Force -Confirm:$false

#shut down vcenter, vcenter host
Connect-VIServer -Server $vCenterHost
#Connect-VIServer -Server $vCenterHost -user root -password enteryourpasswordthere

$poweredOnVm = Get-VM | where-object {$_.PowerState -eq "PoweredOn"}

ForEach ( $vm in $poweredOnVm )
{
    $guestInfo = get-view -Id $vm.ID
    if ($guestInfo.config.Tools.ToolsVersion -eq 0)
    {
        Stop-VM $vm -confirm:$false | out-null
    }
    else
    {
        Stop-VMGuest $vm -Confirm:$false | out-null
    }
}

#shutdown ESXi host which held vcenter
$vCenterVm = Get-VM | where-object {$_.name -eq $vCenterVMName}

while ($vCenterVm.PowerState -eq "PoweredOn")
{
    sleep 60
    $vCenterVm = Get-VM | where-object {$_.name -eq $vCenterVMName}
    write-host "sleep"
}

get-VMHost | Stop-VMHost -force:$true -runasync:$true -confirm:$false | out-null

Disconnect-VIServer -Server $vCenterHost -Force -Confirm:$false
