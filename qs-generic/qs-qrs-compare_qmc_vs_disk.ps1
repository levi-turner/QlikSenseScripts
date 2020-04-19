#--------------------------------------------------------------------------------------------------------------------------------
#
# Script Name: qlik_sense-compare_qmc_vs_disk.ps1
# Description: Compares what files exist on disk vs. the QMC
# Dependency: None
# Requirements: Run from the Central node _as_ the service account
# 
#   Version     Date        Author          Change Notes
#   0.1         2018-03-23  Levi Turner     Initial Version 
# 
#--------------------------------------------------------------------------------------------------------------------------------

# Dummy value for the headers
$hdrs = @{}
# Add in the Xrfkey value to the headers
# https://help.qlik.com/en-US/sense-developer/February2018/Subsystems/RepositoryServiceAPI/Content/RepositoryServiceAPI/RepositoryServiceAPI-Connect-API-Using-Xrfkey-Headers.htm
$hdrs.Add("X-Qlik-Xrfkey","examplexrfkey123")
# Add in the User account to the headers
<# 
Any account with sufficient permissions work
If using INTERNAL accounts, then sa_api is preferred
for tracking or auditing purposes.
Reference: https://help.qlik.com/en-US/sense-developer/February2018/Subsystems/RepositoryServiceAPI/Content/RepositoryServiceAPI/RepositoryServiceAPI-Injected-Request-Headers-X-Qlik-User.htm
#>
$hdrs.Add("X-Qlik-User", "UserDirectory=INTERNAL; UserId=sa_api")
# Grab the Client certificate to trust the QRS request
$cert = Get-ChildItem -Path "Cert:\CurrentUser\My" | Where {$_.Subject -like '*QlikClient*'}
# Construct the FQDN
# Use case is being run on the Qlik Sense Server
$myFQDN=(Get-WmiObject win32_computersystem).DNSHostName+"."+(Get-WmiObject win32_computersystem).Domain
$myFQDN = $myFQDN.ToLower()
# Handle TLS 1.2 only environments
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12'
# Get the list of apps
Write-Host "Getting App List from QMC"
$QRSAppList = Invoke-RestMethod -Uri "https://$($myFQDN):4242/qrs/app/full?xrfkey=examplexrfkey123" -Method Get -Headers $hdrs -ContentType 'application/json' -Certificate $cert
# Truncate to just the GUIDs of the apps
$QRSAppListIDs = $QRSAppList.id
Write-Host "App List from QMC captured"
Read-Host "Press Enter if no errors present"

Write-Host "Getting Apps UNC path"
$rawoutput=$true
$ServiceCluster = Invoke-RestMethod -Uri "https://$($myFQDN):4242/qrs/servicecluster/full?xrfkey=examplexrfkey123" -Method Get -Headers $hdrs -ContentType 'application/json' -Certificate $cert
$AppFolder = $ServiceCluster.settings.sharedPersistenceProperties.appFolder
Write-Host "Apps UNC path captured"
Read-Host "Press Enter if no errors present"

Set-Location $AppFolder
Write-Host "Compare files on disk vs. QMC"
$DiskApps= get-childitem $AppFolder -File
$DiskAppList = $DiskApps | where {$_.extension -ne ".lock"} | Select-Object Name
$Comparison = Compare-Object -ReferenceObject $DiskApps -DifferenceObject $QRSAppListIDs | ForEach-Object { $_.InputObject }
Write-Host "These apps either exist in the QMC and not on disk or the reverse"
echo $Comparison
$Comparison | Out-File -filepath $PSScriptRoot\Diff.txt 
Read-Host "Press Enter end this process"