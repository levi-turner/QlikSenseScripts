#------------------------------------------------------------------------------------
#
# Script Name: qsr_restore.ps1
# Description: This is a script to assist with restoring QSR's to aid with customer replications
#				This script will:
#								Install Qlik Sense
#								Restore a QSR
#								Change the share path
#								Start services to restore hostname
#								Elevate a specified user
# 				User Inputs required:
#                               Have a .TAR located on the Root of the C drive
#               Assumptions /
#               Hardcodded Values:
#                               Service Account = DOMAIN\Administrator
#                               Password for accounts = Password123!
#   Version     Date        Author          Change Notes
#   0.1         2017-12-20  Levi Turner     Initial Version
#   0.2         2017-12-20  Levi Turner     Switched to Get-Service method for service start / stop over net start / stop
#   0.3         2017-12-27  Levi Turner     Powershell does not like launching command line arguments directly, it seems
#   0.4         2018-01-02  Levi Turner     pgpass added for the .SQLs
#                                           Qlik Cli invocation to handle creating the user record
#   0.5         2018-01-02  Levi Turner     Added pauses. Clean run through
#   0.6         2018-01-10  Levi Turner     If-Exists checks / Sept/Nov Toggle
#   0.8         2018-02-28  Levi Turner     Implemented the direct QRS call (adds support for Forms auth on default VP)
#   0.9         2018-02-28  Levi Turner     Cleaned up the QRS initialization logic to search for .LOG rather than hardcoded number
#   0.92        2018-03-04  Levi Turner     Combined Scripts + extended version check across years
#   0.94        2018-03-04  Levi Turner     Removed repro_elevation.sql dependency
#   1.0         2018-03-09  Levi Turner     Removed .pgpass dependency (using $env:PGPASSWORD = 'Password123!')
#                                           More obvious logging
#   1.1         2018-04-12  Levi Turner     Support for 2018-04 (QLIK-87603 is a blocker here)
#                                           Even more logging
#   1.2         2018-06-21  Levi Turner     Adding Support for 2018-06
#                                           Adding Admin elevation catch
#   1.3         2018-06-22  Levi Turner     Building out spc.cfg dynamically inline
#                                           Adding catch for multiple .TARs in the Root of C (Pierce is silly)
#   1.4         2018-07-06  Levi Turner     Doing some cleanup
#                                           Build the .SQL inline rather than copying it
#   1.5         2018-08-30  Levi Turner     Removed Qlik-CLI dependency
#                                           Added robustness to the elevation when there's more than 1 DOMAIN user
#                                           Support for 2018-09
# 
# TODO:
#   Toggle Internal (copy) vs. External (wget / build) [Long-term]
#   Globalization? [Requires feedback from Global Support team]
#
# Robustness checks not present:
#   Qlik Sense install (y/n)
#   pg_dump succeeds (y/n)
#   Others?
#
# On-boarding a new build:
#   Move build to DropZone under the naming convention \\Dropzoneqvcloud\Dropzone\Applications\Qlik Sense\$QSVersion\Qlik_Sense_setup.exe
#   Manual validation of the restorehostname method works?
#       Doesn't: Check documentation
#           No doc changes: Bug
#           Doc changes: Integrate new method
#       Does:
#           Add matching on turrible if/elseif/else chunk on lines 81-94
#           Add line to match the version to a restore method on lines 239-247
#------------------------------------------------------------------------------------

# Admin rights catch
If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).
IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Warning "You do not have Administrator rights to run this script!`nPlease re-run this script as an Administrator!"
    Break
}

# Ensure that the Temp directory exists
Set-Location /
if (Test-Path C:\Temp) {
     Write-Host "C:\Temp already exists." -ForegroundColor Green
} else {
    Write-Host "Creating Temp directory for staging files" -ForegroundColor Green
    New-Item -Name Temp -ItemType directory
}

# Toggle between June / Sept / Nov / Feb / April / June / Sept
Write-Host "Next you will enter the Qlik Sense Version" -ForegroundColor Green
Write-Host "Enter the version in YYYY-MM format" -ForegroundColor Green
$QSVersion = Read-Host -Prompt 'Input Qlik Sense Build (e.g. 2017-06)'

if ($($QSVersion) -eq '2017-06') {
    Write-Host "This script will now silently install June 2017" -ForegroundColor Green
} elseif ($($QSVersion) -eq '2017-09') {Write-Host "This script will now silently install September 2017" -ForegroundColor Green}
  elseif ($($QSVersion) -eq '2017-11') {Write-Host "This script will now silently install November 2017" -ForegroundColor Green}
  elseif ($($QSVersion) -eq '2018-02') {Write-Host "This script will now silently install February 2018" -ForegroundColor Green}
  elseif ($($QSVersion) -eq '2018-04') {Write-Host "This script will now silently install April 2018" -ForegroundColor Green }
  elseif ($($QSVersion) -eq '2018-06') {Write-Host "This script will now silently install June 2018" -ForegroundColor Green }
  elseif ($($QSVersion) -eq '2018-09') {Write-Host "This script will now silently install September 2018" -ForegroundColor Green }
  else 
    {
        Write-Warning "Invalid/Unsupported build" 
        Read-Host "This script will terminate."
        exit
    }

<# Unimplemented external support
switch ($QSVersion)
{
	2017-06{ $build = '11.11'}
	2017-09{ $build = '11.14'}
	2017-11{ $build = '11.24'}
	2018-02{ $build = '12.52'}
}

Grab relevant version of Qlik Sense
if (Test-Path C:\temp\Qlik_Sense_setup.exe) {
    Write-Host "Qlik Sense already downloaded."
} else {
    Invoke-WebRequest https://da3hntz84uekx.cloudfront.net/QlikSense/$build/0/_MSI/Qlik_Sense_setup.exe -OutFile C:\temp\Qlik_Sense_setup.exe
    Write-Host "Qlik_Sense_setup.exe staged"

}
#>

# Copy the selected version of Qlik Sense to the staging path

if (Test-Path C:\temp\Qlik_Sense_setup.exe) {
    Write-Host "Removing previously staged Qlik Sense installer" -ForegroundColor Green
    Remove-Item -Path "C:\temp\Qlik_Sense_setup.exe" -Force
    Copy-Item "\\Dropzoneqvcloud\Dropzone\Applications\Qlik Sense\$QSVersion\Qlik_Sense_setup.exe" C:\temp\Qlik_Sense_setup.exe
    Write-Host "Qlik_Sense_setup.exe staged" -ForegroundColor Green
} else {
    Copy-Item "\\Dropzoneqvcloud\Dropzone\Applications\Qlik Sense\$QSVersion\Qlik_Sense_setup.exe" C:\temp\Qlik_Sense_setup.exe
    Write-Host "Qlik_Sense_setup.exe staged" -ForegroundColor Green
}

# Create Share Path
Set-Location -Path C:\

if (Test-Path C:\QlikShare) {
     Write-Host "C:\QlikShare already exists." -ForegroundColor Green
} else {
    Write-Host "Creating QlikShare directory for Shared Persistence Storage" -ForegroundColor Green
    New-Item -Name QlikShare -ItemType directory
}
# Create SMB Share
if(!(Get-SMBShare -Name QlikShare -ea 0)){
    New-SmbShare -Name "QlikShare" -Path "C:\QlikShare" -FullAccess "DOMAIN\Administrator" | Out-Null
    Write-Host "Creating QlikShare SMB Share for Shared Persistence Storage" -ForegroundColor Green
}

if (Test-Path C:\temp\spc.cfg) {
    Write-Host "Removing previously staged Shared Persistence Configuration" -ForegroundColor Green
    Remove-Item -Path "C:\temp\spc.cfg" -Force
} else {

}
Set-Location -Path C:\Temp
# Create spc.cfg
$SPShare = '\\' + $($env:computername) + '\QlikShare'
$filePath = "C:\Temp\spc.cfg" # Set the File Name
$XmlWriter = New-Object System.XMl.XmlTextWriter($filePath,$Null) # Create The Document
$xmlWriter.Formatting = "Indented" # Set The Formatting
$xmlWriter.Indentation = "4"
$xmlWriter.WriteStartDocument() # Write the XML Decleration
$xmlWriter.WriteStartElement("SharedPersistenceConfiguration") # Write Root Element
$xmlWriter.WriteElementString("DbUserName","qliksenserepository") # <-- Begin writing the XML file
$xmlWriter.WriteElementString("DbUserPassword","Password123!")
$xmlWriter.WriteElementString("DbHost","localhost")
$xmlWriter.WriteElementString("DbPort","4432")
$xmlWriter.WriteElementString("RootDir","$($SPShare)")
$xmlWriter.WriteElementString("StaticContentRootDir","$($SPShare)" + "\StaticContent")
$xmlWriter.WriteElementString("CustomDataRootDir","$($SPShare)" + "\CustomData")
$xmlWriter.WriteElementString("ArchivedLogsDir","$($SPShare)" + "\ArchivedLogs")
$xmlWriter.WriteElementString("AppsDir","$($SPShare)" + "\Apps")
$xmlWriter.WriteElementString("CreateCluster","true")
$xmlWriter.WriteElementString("InstallLocalDb","true")
$xmlWriter.WriteElementString("ConfigureDbListener","true")
$xmlWriter.WriteElementString("ListenAddresses","*")
$xmlWriter.WriteElementString("IpRange","0.0.0.0/0")
$xmlWriter.WriteEndElement  | Out-Null # <-- Closing RootElement
$xmlWriter.WriteEndDocument() | Out-Null # End the XML Document
$xmlWriter.Finalize | Out-Null # Finish The Document
$xmlWriter.Flush | Out-Null
$xmlWriter.Close() | Out-Null

Write-Host "Shared Persistence Configuration staged" -ForegroundColor Green

Set-Location C:\Temp
# Unblock the EXE, usually unneeded
Unblock-File .\Qlik_Sense_setup.exe
# Silent install > do not start services
Write-Host "Qlik Sense $($QSVersion) will be installed" -ForegroundColor Green
Start-Process .\Qlik_Sense_setup.exe "-s userwithdomain=domain\Administrator userpassword=Password123! dbpassword=Password123! sharedpersistenceconfig=C:\Temp\spc.cfg skipstartservices=1" -wait
Write-Host "Qlik Sense Installed" -ForegroundColor Green

# Start the Repo DB
Get-Service QlikSenseRepositoryDatabase -ComputerName localhost | Start-Service

Set-Location "C:\Program Files\Qlik\Sense\Repository\PostgreSQL\9.6\bin\"
# Set environmental variable to set postgres user password
$env:PGPASSWORD = 'Password123!';

# Catch for multiple or no .TARs in the Root of C
$RootDir = get-childitem C:\
$TarList = $RootDir | where {$_.extension -eq ".tar"}
$TarListCount = ( $TarList | Measure-Object ).Count;

Do {
        
    if($($TarListCount) -ne "1") {
        Write-Host "Please ensure that only the target .TAR exists in C:\ or that the target .TAR is in C:\" -ForegroundColor Green
        start-sleep 5
        $RootDir = get-childitem C:\
        $TarList = $RootDir | where {$_.extension -eq ".tar"}
        $TarListCount = ( $TarList | Measure-Object ).Count;
    }
    else{
    }
}
Until($($TarListCount) -eq "1")

# Restore the database
Write-Host "Begin restoration of the Repository Database" -ForegroundColor Green
Start-Process .\pg_restore.exe "--host localhost --port 4432 --username postgres --dbname QSR c:\$TarList" -Wait
Write-Host "Repository Database Restored" -ForegroundColor Green

# Inject in the share path to a local path
Set-Location C:\"Program Files"\Qlik\Sense\Repository\PostgreSQL\9.6\bin
if (Test-Path "C:\Program Files\Qlik\Sense\Repository\PostgreSQL\9.6\bin\servicecluster.sql") {
    Write-Host "servicecluster.sql already exists." -ForegroundColor Green
} else {
    "UPDATE $([char]34)ServiceClusterSettingsSharedPersistenceProperties$([char]34) SET $([char]34)RootFolder$([char]34)=$([char]39)$($SPShare)$([char]39);" | Set-Content servicecluster.sql -Encoding Ascii
    "UPDATE $([char]34)ServiceClusterSettingsSharedPersistenceProperties$([char]34) SET $([char]34)AppFolder$([char]34)=$([char]39)$($SPShare)\Apps$([char]39);" | Add-Content servicecluster.sql -Encoding Ascii
    "UPDATE $([char]34)ServiceClusterSettingsSharedPersistenceProperties$([char]34) SET $([char]34)StaticContentRootFolder$([char]34)=$([char]39)$($SPShare)\StaticContent$([char]39);" | Add-Content servicecluster.sql -Encoding Ascii
    "UPDATE $([char]34)ServiceClusterSettingsSharedPersistenceProperties$([char]34) SET $([char]34)Connector32RootFolder$([char]34)=$([char]39)$($SPShare)\CustomData$([char]39);" | Add-Content servicecluster.sql -Encoding Ascii
    "UPDATE $([char]34)ServiceClusterSettingsSharedPersistenceProperties$([char]34) SET $([char]34)Connector64RootFolder$([char]34)=$([char]39)$($SPShare)\CustomData$([char]39);" | Add-Content servicecluster.sql -Encoding Ascii
    "UPDATE $([char]34)ServiceClusterSettingsSharedPersistenceProperties$([char]34) SET $([char]34)ArchivedLogsRootFolder$([char]34)=$([char]39)$($SPShare)\ArchivedLogs$([char]39);" | Add-Content servicecluster.sql -Encoding Ascii
    Write-Host "Service Cluster Injection SQL staged" -ForegroundColor Green
}
Write-Host "Begin injection of the Service Cluster to Support paths" -ForegroundColor Green
Start-Process .\psql.exe "--host localhost --port 4432 -U postgres --dbname QSR -e -f servicecluster.sql"

Write-Host "Service Cluster injected" -ForegroundColor Green

# Set the restore method based on the build
switch ($QSVersion)
    {
        2017-06{ $restoremethod = 'config'}
        2017-09{ $restoremethod = 'restorehostname'}
        2017-11{ $restoremethod = 'restorehostname'}
        2018-02{ $restoremethod = 'restorehostname'}
        2018-04{ $restoremethod = 'sql'}
        2018-06{ $restoremethod = 'restorehostname'}
        2018-09{ $restoremethod = 'restorehostname'}
    }

# Restore the hostname
if ($($restoremethod) -eq 'config') {
        Write-Host "This script will now restore the Hostname for June 2017" -ForegroundColor Green
        $RestoreHostNameConfig = 'C:\Program Files\Qlik\Sense\Repository\Repository.exe.config'
        (Get-Content $RestoreHostNameConfig) -replace '<add key="EnableRestoreHostname" value="false" />', '<add key="EnableRestoreHostname" value="true" />' | Set-Content $RestoreHostNameConfig
        Write-Host "EnableRestoreHostname key modified"

} elseif ($($restoremethod) -eq 'restorehostname') {
        Write-Host "This script will now restore the Hostname for $($QSVersion) using restorehostname method" -ForegroundColor Green
        Set-Location C:\"Program Files"\Qlik\Sense\Repository
        Start-Process  .\Repository.exe  "-bootstrap -standalone -restorehostname" -Wait
        Write-Host "Bootstrap run" -ForegroundColor Green
    }
   elseif ($($restoremethod) -eq 'sql') {
        Write-Host "This script will now restore the Hostname for April 2018" -ForegroundColor Green
        Set-Location C:\"Program Files"\Qlik\Sense\Repository\PostgreSQL\9.6\bin
        $Data = Get-Content C:\ProgramData\Qlik\Sense\Host.cfg
        $FQDN = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($($Data)))
        $elevate1 = "UPDATE `"LocalConfigs`" SET `"HostName`" = '$($FQDN)' WHERE LOWER(`"HostName`") = (SELECT `"HostName`" FROM `"ServerNodeConfigurations`" WHERE `"IsCentral`"='true')`;"
        $elevate2 = "UPDATE `"ServerNodeConfigurations`" SET `"HostName`" = '$($FQDN)' WHERE `"HostName`" = (SELECT `"HostName`" FROM `"ServerNodeConfigurations`" WHERE `"IsCentral`"='true');"
        $elevate1 | set-content qs_2018-04-elevate1.sql -Encoding Ascii
        $elevate2 | set-content qs_2018-04-elevate2.sql -Encoding Ascii
        Start-Process .\psql.exe "--host localhost --port 4432 -U postgres --dbname QSR -e -f qs_2018-04-elevate1.sql"
        start-sleep 5
        Start-Process .\psql.exe "--host localhost --port 4432 -U postgres --dbname QSR -e -f qs_2018-04-elevate2.sql"
        Write-Host "LocalConfigs & ServerNodeConfigurations adjusted" -ForegroundColor Green
    }
  else 
    {
        Write-Host "Invalid/Unsupported build" -ForegroundColor Green
        exit
    }

# Start services to issue Qlik CLI call to create the user record
Get-Service QlikSenseServiceDispatcher -ComputerName localhost | Start-Service
Get-Service QlikSenseRepositoryService -ComputerName localhost | Start-Service
Get-Service QlikSenseProxyService -ComputerName localhost | Start-Service

# Loop until the Repo is fully online
Set-Location C:\ProgramData\Qlik\Sense\Log\Repository\Trace

$loglist = 10

# Loop until there are no .LOG files which is a signal that the Repo is online
# since the Repo will archive them when it is fully initialized
    Do {
        
        if($loglist -eq 0) {"Repository Initialized"}
        else{
        Write-Host "Repository Still Initializing" -ForegroundColor Green
        start-sleep 5
        $loglist = Get-ChildItem -Recurse -Include *.log| Measure-Object | %{$_.Count}
        }
    }
    Until($loglist -eq 0)

# Artificial Sleep to prevent failure on the QRS API call
start-sleep 10
# Call QSR APIs to create the account for DOMAIN\Administrator then elevate to RootAdmin
$hdrs = @{}
$hdrs.Add("X-Qlik-Xrfkey","examplexrfkey123")
# Logging in as DOMAIN\Administrator
$hdrs.Add("X-Qlik-User", "UserDirectory=DOMAIN; UserId=Administrator")
$cert = Get-ChildItem -Path "Cert:\CurrentUser\My" | Where {$_.Subject -like '*QlikClient*'}
$Data = Get-Content C:\ProgramData\Qlik\Sense\Host.cfg
$FQDN = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($($Data)))
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12'
Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/about?xrfkey=examplexrfkey123" -Method Get -Headers $hdrs -ContentType 'application/json' -Certificate $cert  | Out-Null
Write-Host "Account created in QSR" -ForegroundColor Green

$hdrs = @{}
$hdrs.Add("X-Qlik-Xrfkey","examplexrfkey123")
# Now log in as INTERNAL account to elevate
$hdrs.Add("X-Qlik-User", "UserDirectory=INTERNAL; UserId=sa_api")
$userfull = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/user/full?filter=(userdirectory eq 'domain' and name eq 'Administrator')&xrfkey=examplexrfkey123" -Method Get -Headers $hdrs -ContentType 'application/json' -Certificate $cert
$adminuserbody = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/user/$($userfull.id)?xrfkey=examplexrfkey123" -Method Get -Headers $hdrs -ContentType 'application/json' -Certificate $cert
$adminuserbody | Add-Member role RootAdmin -Force
$adminuserbodyjson = $adminuserbody | ConvertTo-Json
$body = $adminuserbodyjson
Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/user/$($userfull.id)?xrfkey=examplexrfkey123" -Method Put -Body $body -Headers $hdrs -ContentType 'application/json' -Certificate $cert  | Out-Null

Write-Host "Account elevated" -ForegroundColor Green

Get-Service QlikSenseServiceDispatcher -ComputerName localhost | Start-Service
Get-Service QlikSensePrintingService -ComputerName localhost | Start-Service
Get-Service QlikSenseEngineService -ComputerName localhost | Start-Service
Get-Service QlikSenseSchedulerService -ComputerName localhost | Start-Service

Write-Host "Clean up activities" -ForegroundColor Green
if ($($QSVersion) -eq '2018-04') 
    {
        Remove-Item -Path "C:\Program Files\Qlik\Sense\Repository\PostgreSQL\9.6\bin\qs_2018-04-elevate1.sql" -Force | Out-Null
        Write-Host "qs_2018-04-elevate1.sql deleted" -ForegroundColor Green
        Remove-Item -Path "C:\Program Files\Qlik\Sense\Repository\PostgreSQL\9.6\bin\qs_2018-04-elevate2.sql" -Force | Out-Null
        Write-Host "qs_2018-04-elevate2.sql deleted" -ForegroundColor Green
    }
else 
    {}
Remove-Item -Path "C:\temp\Qlik_Sense_setup.exe" -Force | Out-Null
Write-Host "Installer deleted" -ForegroundColor Green
Remove-Item -Path "C:\Program Files\Qlik\Sense\Repository\PostgreSQL\9.6\bin\servicecluster.sql" -Force | Out-Null
Write-Host "servicecluster.sql deleted" -ForegroundColor Green
Remove-Item -Path "C:\Temp\spc.cfg" -Force | Out-Null
Write-Host "spc.cfg deleted"