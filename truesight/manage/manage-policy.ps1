<#
.Synopsis
    Manage TrueSight Operations Management policies via rest API

.Description
    Manage TrueSight Operations Management policies via rest API
    
    The script is capable of export and import Truesight Monitoring policies into json file.

    Overwrite of existing policies isn't allowed by design, please modify the policy name in the exported json file then import it, there will be a new polic then simple enable/disable the required.

    Important! The passwords of added systems in the policy (eg. vcenter, netapp, hardware monitoring) will be present in the json file in plain text!

.Notes
    Author        : Andras Babos <andrasbabos@gmail.com>
    Source        : will be added later

.Parameter configfile
    Configuration file which can hold default values for most of the parameters.
    default value is config.ini
    can be set via:
    - command line parameter

.Parameter username
    username to log in via rest API, standard TSOM web GUI user is good.
    can be set via:
    - config file
    - command line parameter
    - during script run

.Parameter password
    password to log in via rest API, standard TSOM web GUI user is good.
    can be set via:
    - config file
    - command line parameter
    - during script run

.Parameter tenantname
    Tenantname is needed for authentication the default value is BMCRealm or *.
    can be set via:
    - config file
    - command line parameter

.Parameter command
    The command which will be executed:
    - list - list all policy names
    - export - export one policy
    - exportall - export all policies
    - import - import one policy
    can be set via:
    - command line parameter
    - during script run

.Parameter tspsrooturl
    TrueSight Presentation Server root URL, in the format of: https://<TSPShostname>:<port>/tsws/10.0/api
    can be set via:
    - config file
    - command line parameter

.Parameter tsimrooturl
    TrueSight Infrastructure Management root URL, in the format of: http|https://<serverHost>:<port>/bppmws/api
    can be set via:
    - config file
    - command line parameter

.Parameter exportdir
    target directory to export policy
    can be set via:
    - config file
    - command line parameter

.Parameter importfile
    source policy file to import
    can be set via:
    - command line parameter
    - during script run

.Parameter policyname
    policy name for export
    can be set via:
    - command line parameter
    - during script run

.Example
    manage-policy.ps1
    -----------
    Description
    Fully interactive execution of the script.

.Example
    manage-policy.ps1 -command list
    -----------
    Description
    Fully automatic export of all policies if the proper config file present.
    
.Example
    manage-policy.ps1 -command export -policyname "my policy name" -username my_username -password my_password -exportdir c:\Users\username\Documents\tsom\dump\
    -----------
    Description
    Fully automatic export of a policy, most of the parameters set via command line.

    #>

# process command line
## cmdletbindig is used for verbose, debug parameters
[CmdletBinding()]
param (
    [string]$configFile = "config.ini",
    [string]$userName,
    [string]$password,
    [string]$tenantName,
    [string]$command,
    [string]$tspsRootURL,
    [string]$tsimRootURL,
    [string]$exportDir,
    [string]$importFile,
    [string]$policyName
)

# functions
## load conifg.ini to hash table
## https://devblogs.microsoft.com/scripting/use-powershell-to-work-with-any-ini-file/
. ./get-inicontent.ps1

function tsomLogin
{
    write-verbose "## tsom login ##"
    $loginUrl = $($tspsRootURL + "/authenticate/login")
    $tsomResponse = Invoke-RestMethod -Method Post -Uri $loginUrl -Body $loginBody
    $authToken = $tsomResponse.response.authToken
    return $authToken
}

function tsomLogout
{
    write-verbose "## tsom logout ##"
    $logoutUrl = $($tspsRootURL + "/authenticate/logout")
    $logoutBody = @{
        authToken = $authToken
    }
    $tsomResponse = Invoke-RestMethod -Method Post -Uri $logoutUrl -Body $logoutBody
}

function tsomGetPolicies
{
    write-verbose "## get list of policies ##"
    $eventBody = @{
        "filterCriteria" = @{
            "tenantName" = ""
        }
        "type" = "monitoringpolicy"
    } | ConvertTo-Json

    $eventUrl = $($tspsRootURL + "/unifiedadmin/Policy/list?responseType=basic")
    $tsomResponse = Invoke-RestMethod -Method Post -Headers $headers -Uri $eventUrl -Body $eventBody -ContentType "application/json"
    return $tsomResponse.response.policyList
}

function tsomExportPolicy
{
    write-verbose "## export config of a policy ##"
    forEach ($policy in $policyList)
    {
        if ($policy.resourceName -eq $policyName)
        {
            $eventUrl = $($tspsRootURL + "/unifiedadmin/Policy/" + $policy.resourceId + "/list?&idType=id&escNcr=true")
            $tsomResponse = Invoke-RestMethod -Method Get -Headers $headers -Uri $eventUrl
            $tsomResponse.response | Select-Object monitoringPolicy | ConvertTo-Json -Depth 100 | Out-File -FilePath $($exportDir + "policy_" + $policyName + ".json")
        }
    }
}

function tsomExportPolicies
{
    write-verbose "## export configs of policies ##"
    forEach ($policy in $policyList)
    {
        $eventUrl = $($tspsRootURL + "/unifiedadmin/Policy/" + $policy.resourceId + "/list?&idType=id&escNcr=true")
        $tsomResponse = Invoke-RestMethod -Method Get -Headers $headers -Uri $eventUrl
        $tsomResponse.response | Select-Object monitoringPolicy | ConvertTo-Json -Depth 100 | Out-File -FilePath $($exportDir + "policy_" + $policy.resourceName + ".json")
    }
}
function tsomImportPolicy
{
    write-verbose "## import policy ##"
    $eventBody = Get-Content $importFile
    $eventUrl = $($tspsRootURL + "/unifiedadmin/MonitoringPolicy/create")
    $tsomResponse = Invoke-RestMethod -Method Post -Headers $headers -Uri $eventUrl -Body $eventBody -ContentType "application/json"
    return $tsomResponse.response
}

# main
## create default variables
$loginBody = @{}

## load config.ini
$configIni = Get-IniContent $configFile

### config file check, extend if needed
#write-debug "configIni.login.userName = $($configIni.login.username)"
#write-debug "configIni.url.tsps = $($configIni.url.tsps)"
#write-debug "configIni.url.tsim = $($configIni.url.tsim)"

# write-debug can't handle hash tables, this is a workaround if needed
#if ($DebugPreference -eq "Inquire")
#{
    #write-debug "## configIni variable ##"
    #$configIni.login | Format-Table
#}

## set running variables from config file, command line or ask for it if it still missing
if (-not ([string]::IsNullOrEmpty($userName)))
{
    $loginBody.username = $userName
}
elseif (-not ([string]::IsNullOrEmpty($configIni.login.userName)))
{
    $loginBody.username = $configIni.login.userName
}
else
{
    $loginBody.username = read-host "Enter user name for TSOM"
}

if (-not ([string]::IsNullOrEmpty($password)))
{
    $loginBody.password = $password
}
elseif (-not ([string]::IsNullOrEmpty($configIni.login.password)))
{
    $loginBody.password = $configIni.login.password
}
else
{
    $securedValue = Read-Host "Enter password for TSOM" -AsSecureString
    $binarystr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securedValue)
    $loginBody.password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($binarystr)
}

if (-not ([string]::IsNullOrEmpty($tenantName)))
{
    $loginBody.tenantName = $tenantName
}
elseif (-not ([string]::IsNullOrEmpty($configIni.login.tenantName)))
{
    $loginBody.tenantName = $configIni.login.tenantName
}
else
{
    $loginBody.tenantName = read-host "Enter TSOM tenant name"
}

if ([string]::IsNullOrEmpty($command))
{
    $command = read-host "Enter command to execute (list, export, exportall, import)"
}

if (-not ([string]::IsNullOrEmpty($tspsrooturl)))
{
    #as far as i remember i commented out these because the commandline variable name is the same as the in script variable name and I don't need to do anything
    #$tspsRootURL = $tspsrooturl
}
elseif (-not ([string]::IsNullOrEmpty($configIni.url.tsps)))
{
    $tspsRootURL = $configIni.url.tsps
}
else
{
    $tspsRootURL = read-host "Enter TSPS root url"
}

if (-not ([string]::IsNullOrEmpty($tsimrooturl)))
{
    #$tsimRootURL = $tsimrooturl
}
elseif (-not ([string]::IsNullOrEmpty($configIni.url.tsim)))
{
    $tsimRootURL = $configIni.url.tsim
}
else
{
    $tsimRootURL = read-host "Enter TSIM root url"
}

if (($command -eq "exportall") -or ($command -eq "export"))
{
    if ((-not ([string]::IsNullOrEmpty($exportDir))))
    {
        #$exportDir = $exportdir
    }
    elseif (-not ([string]::IsNullOrEmpty($configIni.file.exportdir)))
    {
        $exportDir = $configIni.file.exportdir
    }
    else
    {
        $exportDir = read-host "Enter export directory"
    }
}

if (([string]::IsNullOrEmpty($importFile)) -and ($command -eq "import"))
{
    $importFile = read-host "Enter file to import (with full path)"
}

if (([string]::IsNullOrEmpty($policyName)) -and ($command -eq "export"))
{
    $policyName = read-host "Enter policy name to export"
}

### final config variables check, extend if needed
write-debug "exportDir = $($exportDir)"

## acquire login token
$authToken = tsomLogin
$headers = @{ Authorization = "authToken $authToken" }

## switch to execute the command
switch ($command) 
{
    "list"
    {
        $policyList = tsomGetPolicies
        forEach ($policy in $policyList)
        {
            $policy.resourceName
        }
    }

    "export"
    {
        $policyList = tsomGetPolicies
        tsomExportPolicy
    }

    "exportall"
    {
        $policyList = tsomGetPolicies
        tsomExportPolicies
    }

    "import"
    {
        tsomImportPolicy
    }

    default
    {
        "please check the help with: get-help .\$($MyInvocation.MyCommand.Name)"
    }
}

## logout
tsomLogout
