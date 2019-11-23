write-output "## source variables ##"
. .\variables.ps1

#login
write-output "## login ##"
$tsomLoginUrl = $($tspsURL + "/authenticate/login")
$tsomLogin = Invoke-RestMethod -Method Post -Uri $tsomLoginUrl -Body $tsomLoginBody
$tsomAuthToken = $tsomLogin.response.authToken
$tsomHeaders = @{ Authorization = "authToken $tsomAuthToken" }

#query all devices
write-output "## tsom query ##"
$tsomEventUrl = $($tspsURL + "/omprovider/devices?tenantId=*&deviceEntityType=all&parentDeviceId=-1")
$tsomResponse = Invoke-RestMethod -Method Get -Headers $tsomHeaders -Uri $tsomEventUrl

write-output "## tsom logout ##"
$tsomBody = @{
    authToken = $tsomAuthToken
}

$tsomLogoutUrl =  $($tspsURL + "/authenticate/logout")
$tsomLogout = Invoke-RestMethod -Method Post -Uri $tsomLogoutUrl -Body $tsomBody

write-output "## create tsom array ##"
$tsomArray = @{}
$mergedArray = @{}

forEach ($tsomCI in $tsomResponse.responseContent.deviceList)
{
    $tsomKey = $tsomCI.dnsName
    $tsomValue = @{}
    $mergedValue = @{}
    $tsomValue.add("dnsName",$tsomCI.dnsName)
    $tsomValue.add("dispName",$tsomCI.dispName)
    $tsomValue.add("ipAddress",$tsomCI.ipAddress)
    if ($tsomArray.ContainsKey($tsomKey)) {
        if ($mergedArray.ContainsKey($tsomKey)) {
            #read status value, add extra data, write back
            #$mergedArray.$key
        }
        else {
            #add extra data, write back
            $mergedValue.add("check_status","duplicate tsom.dnsName")
            $mergedArray.add($tsomKey, $mergedValue)
        }
    }
    else {
        $tsomArray.add($tsomKey, $tsomValue)
    }
}

write-output "## cmdb login ##"
$cmdbLoginUrl = $($cmdbURL + "/jwt/login")
$cmdbLogin = Invoke-RestMethod -Method Post -Uri $cmdbLoginUrl -Body $cmdbLoginBody
$cmdbAuthToken = $cmdbLogin
$cmdbHeaders = @{ Authorization = "AR-JWT $cmdbAuthToken" }

write-output "## cmdb query and array iteration ##"
$cmdbArray = @{}
$offset = 0
$limit = 100

Do {
    $cmdbDataUrl = -join($cmdbURL, "/cmdb/v1/instance/BMC.ASSET/BMC.CORE/BMC_ComputerSystem?limit=", $limit, "&offset=", $offset, "&fields=Name,Region,SiteGroup,Company,Hostname,IPAddress,MarkAsDeleted,ManagedHostname,ManagementIP")
    $cmdbResponse = Invoke-RestMethod -Method Get -Headers $cmdbHeaders -Uri $cmdbDataUrl
    $offset = $offset + $limit
    write-output "## cmdb query offset $offset ##"

    forEach ($cmdbCI in $cmdbResponse.instances.attributes)
    {
        $cmdbValue = @{}
        $mergedValue = @{}
        $cmdbKey = $cmdbCI.Name
        $cmdbValue.add("Name",$cmdbCI.Name)
        $cmdbValue.add("Hostname",$cmdbCI.Hostname)
        $cmdbValue.add("IPAddress",$cmdbCI.IPAddress)
        $cmdbValue.add("ManagedHostname",$cmdbCI.ManagedHostname)
        $cmdbValue.add("ManagementIP",$cmdbCI.ManagementIP)
        $cmdbValue.add("Region",$cmdbCI.Region)
        $cmdbValue.add("SiteGroup",$cmdbCI.SiteGroup)
        $cmdbValue.add("Company",$cmdbCI.Company)
        $cmdbValue.add("MarkAsDeleted",$cmdbCI.MarkAsDeleted)
        if ($cmdbArray.ContainsKey($cmdbKey)) {
            if ($mergedArray.ContainsKey($cmdbKey)) {
                #read status value, add extra data, write back
            }
            else {
                $mergedValue.add("check_status","duplicate cmdb.Name")
                $mergedArray.add($cmdbKey, $mergedValue)
            }
        }
        else {
            $cmdbArray.add($cmdbKey, $cmdbValue)
        }
    }
} While ($cmdbResponse.instances.attributes.Count -eq $limit)

write-output "## merge tsom to mergedArray ##"
$tsomArray.GetEnumerator() | ForEach-Object {
    $mergedValue = @{}
    if ($mergedArray.ContainsKey($_.key)) {
        $mergedArray[$_.key]["tsom_dnspName"] = $_.value["dnsName"]
        $mergedArray[$_.key]["tsom_dispName"] = $_.value["dispName"]
        $mergedArray[$_.key]["tsom_ipAddress"] = $_.value["ipAddress"]
    }
    else {
        $mergedValue.add("tsom_dnsName",$_.value["dnsName"])
        $mergedValue.add("tsom_dispName",$_.value["dispName"])
        $mergedValue.add("tsom_ipAddress",$_.value["ipAddress"])
        $mergedArray.add($_.key, $mergedValue)
    }
}

write-output "## merge cmdb to mergedArray ##"
$cmdbArray.GetEnumerator() | ForEach-Object {
    $mergedValue = @{}
    if ($mergedArray.ContainsKey($_.key)) {
        $mergedArray[$_.key]["cmdb_Name"] = $_.value["Name"]
        $mergedArray[$_.key]["cmdb_Hostname"] = $_.value["Hostname"]
        $mergedArray[$_.key]["cmdb_IPAddress"] = $_.value["IPAddress"]
        $mergedArray[$_.key]["cmdb_ManagedHostname"] = $_.value["ManagedHostname"]
        $mergedArray[$_.key]["cmdb_ManagementIP"] = $_.value["ManagementIP"]
        $mergedArray[$_.key]["cmdb_Region"] = $_.value["Region"]
        $mergedArray[$_.key]["cmdb_SiteGroup"] = $_.value["SiteGroup"]
        $mergedArray[$_.key]["cmdb_Company"] = $_.value["Company"]
        $mergedArray[$_.key]["cmdb_MarkAsDeleted"] = $_.value["MarkAsDeleted"]
    }
    else {
        $mergedValue.add("cmdb_Name",$_.value["Name"])
        $mergedValue.add("cmdb_Hostname",$_.value["Hostname"])
        $mergedValue.add("cmdb_IPAddress",$_.value["IPAddress"])
        $mergedValue.add("cmdb_ManagedHostname",$_.value["ManagedHostname"])
        $mergedValue.add("cmdb_ManagementIP",$_.value["ManagementIP"])
        $mergedValue.add("cmdb_Region",$_.value["Region"])
        $mergedValue.add("cmdb_SiteGroup",$_.value["SiteGroup"])
        $mergedValue.add("cmdb_Company",$_.value["Company"])
        $mergedValue.add("cmdb_MarkAsDeleted",$_.value["MarkAsDeleted"])
        $mergedArray.add($_.key, $mergedValue)
    }
}

write-output "## add missing keys to mergedArray ##"
$mergeKeys = ("tsom_dnsName","tsom_dispName","tsom_ipAddress","cmdb_Name","cmdb_Hostname","cmdb_IPAddress","cmdb_ManagedHostname","cmdb_ManagementIP","cmdb_Region","cmdb_SiteGroup","cmdb_Company","cmdb_MarkAsDeleted")
$mergedArray.GetEnumerator() | ForEach-Object {
    forEach ($mergeKey in $mergeKeys) {
        if (-Not $mergedArray[$_.key].ContainsKey($mergeKey)) {
            $mergedArray[$_.key][$mergeKey] = "null"
        }
        if ($mergedArray[$_.key].cmdb_Hostname.length -eq 0) {
            $mergedArray[$_.key].cmdb_Hostname = "null"
        }
        if ($mergedArray[$_.key].cmdb_IPAddress.length -eq 0) {
            $mergedArray[$_.key].cmdb_IPAddress = "null"
        }
        if ($mergedArray[$_.key].cmdb_MarkAsDeleted.length -eq 0) {
            $mergedArray[$_.key].cmdb_MarkAsDeleted = "null"
        }
    }
}

write-output "## create compare.csv ##"
$mergedArray.GetEnumerator() | ForEach-Object {
    $tempObject = [pscustomobject]$_.value
    $tempObject = $tempObject | Select-Object tsom_dnsName,tsom_dispName,tsom_ipAddress,cmdb_Name,cmdb_Hostname,cmdb_IPAddress,cmdb_ManagedHostname,cmdb_ManagementIP,cmdb_Region,cmdb_SiteGroup,cmdb_Company,cmdb_MarkAsDeleted
    $tempObject | Export-Csv -NoTypeInformation -Path compare.csv -Append -delimiter ';'
}
