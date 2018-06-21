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
#								Run Qlik Cli install manually
#                               Have a .TAR located on the Root of the C drive
#               Assumptions /
#               Hardcodded Values:
#                               service account = DOMAIN\Administrator
#                               Share path = \\DC1\Share
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
#   1.1         2018-04-12  Levi Turner     Support for April (QLIK-87603 is a blocker here)
#                                           Even more logging
#   1.2         2018-06-21 Levi Turner      Adding Support for 2018-06
#                                           Adding Admin right catch
# TODO:
#
#   Toggle Internal (copy) vs. External (wget / build) [Long-term]
#   Globalization?
#   Validity checks not present
#------------------------------------------------------------------------------------
# Admin rights catch
If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).
IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Warning "You do not have Administrator rights to run this script!`nPlease re-run this script as an Administrator!"
    Break
}

# Stage the install files locally
Set-Location /
if (Test-Path C:\Temp) {
     Write-Host "C:\Temp already exists." -ForegroundColor Green
} else {
    Write-Host "Creating Temp directory for staging files" -ForegroundColor Green
    mkdir Temp
}

# Toggle between June / Sept / Nov / Feb / April 
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
  else 
    {Write-Host "Invalid/Unsupported build" -ForegroundColor Green
    exit
    }

# Unimplemented external support
# switch ($QSVersion)
# {
# 	2017-06{ $build = '11.11'}
# 	2017-09{ $build = '11.14'}
# 	2017-11{ $build = '11.24'}
# 	2018-02{ $build = '12.52'}
# }

# Grab relevant version of Qlik Sense
# if (Test-Path C:\temp\Qlik_Sense_setup.exe) {
#     Write-Host "Qlik Sense already downloaded."
# } else {
#     Invoke-WebRequest https://da3hntz84uekx.cloudfront.net/QlikSense/$build/0/_MSI/Qlik_Sense_setup.exe -OutFile C:\temp\Qlik_Sense_setup.exe
#     Write-Host "Qlik_Sense_setup.exe staged"
# }
# Copy the selected version of Qlik Sense to the staging path
if (Test-Path C:\temp\Qlik_Sense_setup.exe) {
    Write-Host "Qlik Sense already downloaded." -ForegroundColor Green
} else {
    Copy-Item "\\Dropzoneqvcloud\Dropzone\Applications\Qlik Sense\$QSVersion\Qlik_Sense_setup.exe" C:\temp\Qlik_Sense_setup.exe
    Write-Host "Qlik_Sense_setup.exe staged" -ForegroundColor Green
}
# Copy the preconfigured Shared Persistence config to the staging path
if (Test-Path C:\temp\spc.cfg) {
    Write-Host "Qlik Sense SPC Config present." -ForegroundColor Green
} else {
    Copy-Item "\\Dropzoneqvcloud\Dropzone\Private folders\LTU\automation\qsr_restore\spc.cfg" C:\temp\spc.cfg
}
# Check whether Qlik CLI is installed, prompt the user to install it if it isn't installed
# I've not had any luck with installing the Module in-line
if (Get-Module -ListAvailable -Name Qlik-Cli) {
    Write-Host "Qlik-Cli installed " -ForegroundColor Green
} else {
    Copy-Item "\\Dropzoneqvcloud\Dropzone\Private folders\LTU\automation\qsr_restore\install_qlik_cli.ps1" C:\temp\install_qlik_cli.ps1
    Set-Location Temp

    Write-Host "Explorer will launch, run install_qlik_cli.ps1" -ForegroundColor Green
    Read-Host "Press enter to continue with Qlik-CLI installation"
    
    explorer C:\temp

    Read-Host "Press any key after install_qlik_cli.ps1 is installed"
}

Set-Location C:\Temp
# Unblock the EXE, usually unneeded
Unblock-File .\Qlik_Sense_setup.exe
# Silent install > do not start services
Write-Host "Qlik Sense $($QSVersion) will be installed" -ForegroundColor Green
Start-Process .\Qlik_Sense_setup.exe "-s userwithdomain=domain\Administrator userpassword=Password123! dbpassword=Password123! sharedpersistenceconfig=C:\Temp\spc.cfg skipstartservices=1" -wait
Write-Host "Qlik Sense Installed" -ForegroundColor Green

# Start the Repo DB for .SQLs
Get-Service QlikSenseRepositoryDatabase -ComputerName localhost | Start-Service

Set-Location "C:\Program Files\Qlik\Sense\Repository\PostgreSQL\9.6\bin\"
# This will start up a new window, which inherits the password defined in the pgpass.conf copied above
$env:PGPASSWORD = 'Password123!';
$RootDir = get-childitem C:\
$TarList = $RootDir | where {$_.extension -eq ".tar"}
$TarList | format-table name
# Restore the database
Write-Host "Begin restoration of the Repository Database" -ForegroundColor Green
Start-Process .\pg_restore.exe "--host localhost --port 4432 --username postgres --dbname QSR c:\$TarList" -Wait
Write-Host "Repository Database Restored" -ForegroundColor Green
Read-Host "Press Enter to continue"

# TO DO: build the script without dependencies
# servicecluster.sql
# UPDATE "ServiceClusterSettingsSharedPersistenceProperties" SET "RootFolder"='\\DC1\Share'
# UPDATE "ServiceClusterSettingsSharedPersistenceProperties" SET "AppFolder"='\\DC1\Share\Apps'
# UPDATE "ServiceClusterSettingsSharedPersistenceProperties" SET "StaticContentRootFolder"='\\DC1\Share\StaticContent'
# UPDATE "ServiceClusterSettingsSharedPersistenceProperties" SET "Connector32RootFolder"='\\DC1\Share\CustomData'
# UPDATE "ServiceClusterSettingsSharedPersistenceProperties" SET "Connector64RootFolder"='\\DC1\Share\CustomData'
# UPDATE "ServiceClusterSettingsSharedPersistenceProperties" SET "ArchivedLogsRootFolder"='\\DC1\Share\ArchivedLogs'
# Template: "UPDATE $([char]34)Users$([char]34) SET $([char]34)RolesString$([char]34)=$([char]39)RootAdmin$([char]39) WHERE ($([char]34)UserId$([char]34)=$([char]39)qliksensebackup$([char]39) and $([char]34)UserDirectory$([char]34)=$([char]39)$machineName$([char]39));" | set-content elevate.sql -Encoding Ascii

# Inject in the share path to a local path
Set-Location C:\"Program Files"\Qlik\Sense\Repository\PostgreSQL\9.6\bin
if (Test-Path "C:\Program Files\Qlik\Sense\Repository\PostgreSQL\9.6\bin\servicecluster.sql") {
    Write-Host "servicecluster.sql already exists." -ForegroundColor Green
} else {
    Copy-Item "\\Dropzoneqvcloud\Dropzone\Private folders\LTU\automation\qsr_restore\servicecluster.sql" "C:\Program Files\Qlik\Sense\Repository\PostgreSQL\9.6\bin\servicecluster.sql"
    Write-Host "Service Cluster Injection SQL staged" -ForegroundColor Green
}
Write-Host "Begin injection of the Service Cluster to Support paths" -ForegroundColor Green
Start-Process .\psql.exe "--host localhost --port 4432 -U postgres --dbname QSR -e -f servicecluster.sql"

Write-Host "Service Cluster injected" -ForegroundColor Green
Read-Host "Press Enter to continue"

# Restore the hostname

if ($($QSVersion) -eq '2017-06') {
    Write-Host "This script will now restore the Hostname for June 2017" -ForegroundColor Green
    $RestoreHostNameConfig = 'C:\Program Files\Qlik\Sense\Repository\Repository.exe.config'
    (Get-Content $RestoreHostNameConfig) -replace '<add key="EnableRestoreHostname" value="false" />', '<add key="EnableRestoreHostname" value="true" />' | Set-Content $RestoreHostNameConfig

    Write-Host "EnableRestoreHostname key modified"

} elseif ($($QSVersion) -eq '2017-09') {
    Write-Host "This script will now restore the Hostname for Sept 2017" -ForegroundColor Green
    Set-Location C:\"Program Files"\Qlik\Sense\Repository
    Start-Process  .\Repository.exe  "-bootstrap -standalone -restorehostname" -Wait

    Write-Host "Bootstrap run" -ForegroundColor Green
    Read-Host "Press Enter to continue"
}
  elseif ($($QSVersion) -eq '2017-11') {
      Write-Host "This script will now restore the Hostname for Nov 2017" -ForegroundColor Green
      Set-Location C:\"Program Files"\Qlik\Sense\Repository
    Start-Process  .\Repository.exe  "-bootstrap -standalone -restorehostname" -Wait

    Write-Host "Bootstrap run" -ForegroundColor Green
    Read-Host "Press Enter to continue"
    }
  elseif ($($QSVersion) -eq '2018-02') {
        Write-Host "This script will now restore the Hostname for Feb 2018" -ForegroundColor Green
        Set-Location C:\"Program Files"\Qlik\Sense\Repository
        Start-Process  .\Repository.exe  "-bootstrap -standalone -restorehostname" -Wait

        Write-Host "Bootstrap run" -ForegroundColor Green
        Read-Host "Press Enter to continue"
    }
    elseif ($($QSVersion) -eq '2018-04') {
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
        Read-Host "Press Enter to continue"
    }
    elseif ($($QSVersion) -eq '2018-06') {
        Write-Host "This script will now restore the Hostname for June 2018" -ForegroundColor Green
        Set-Location C:\"Program Files"\Qlik\Sense\Repository
        Start-Process  .\Repository.exe  "-bootstrap -standalone -restorehostname" -Wait

        Write-Host "Bootstrap run" -ForegroundColor Green
        Read-Host "Press Enter to continue"
    }
  else 
    {Write-Host "Invalid/Unsupported build" -ForegroundColor Green
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

# Artificial Sleep to prevent failure on the Qlik CLI call
start-sleep 10
# Call Qlik Cli to create the user record

# Connect-Qlik -computername qlikserver1.domain.local -UseDefaultCredentials

$myFQDN=(Get-WmiObject win32_computersystem).DNSHostName+"."+(Get-WmiObject win32_computersystem).Domain
$myFQDN = $myFQDN.ToLower()
# Connect-Qlik -computername $myFQDN -UseDefaultCredentials
Connect-Qlik -computername https://$($myFQDN):4242 -Username DOMAIN\Administrator

Write-Host "Account created in QSR" -ForegroundColor Green
Read-Host "Press Enter to continue"

# Connect as internal account to perform the elevation
Connect-Qlik -Computername https://$($myFQDN):4242 -Username internal\sa_api
# Elevate the DOMAIN\Administrator account to being a RootAdmin
$ElevateUser = Get-QlikUser -filter "userdirectory eq 'DOMAIN'" -raw -full
$ElevateUserID = $ElevateUser.ID
Update-QlikUser -id $ElevateUserID -roles RootAdmin

Write-Host "Account elevated" -ForegroundColor Green
Read-Host "Press Enter to continue"

# Elevation conditional
# if (Test-Path "C:\Program Files\Qlik\Sense\Repository\PostgreSQL\9.6\bin\repro_elevation.sql") {
#     Write-Host "repro_elevation.sql already exists."
# } else {
#     Copy-Item "\\Dropzoneqvcloud\Dropzone\Private folders\LTU\automation\qsr_restore\repro_elevation.sql" "C:\Program Files\Qlik\Sense\Repository\PostgreSQL\9.6\bin\repro_elevation.sql"
#     Write-Host "User elevation SQL staged"
# }

# Set-Location C:\"Program Files"\Qlik\Sense\Repository\PostgreSQL\9.6\bin
# Begin elevating the Admin account
# Start-Process .\psql.exe "-h localhost -p 4432 -U postgres -d QSR -e -f repro_elevation.sql" -Wait

Get-Service QlikSenseServiceDispatcher -ComputerName localhost | Start-Service
Get-Service QlikSensePrintingService -ComputerName localhost | Start-Service
Get-Service QlikSenseEngineService -ComputerName localhost | Start-Service
Get-Service QlikSenseSchedulerService -ComputerName localhost | Start-Service

Write-Host "Clean up activities" -ForegroundColor Green
if ($($QSVersion) -eq '2018-04') {
    Remove-Item -Path "C:\Program Files\Qlik\Sense\Repository\PostgreSQL\9.6\bin\qs_2018-04-elevate1.sql" -Force
Write-Host "qs_2018-04-elevate1.sql deleted" -ForegroundColor Green
Remove-Item -Path "C:\Program Files\Qlik\Sense\Repository\PostgreSQL\9.6\bin\qs_2018-04-elevate2.sql" -Force
Write-Host "qs_2018-04-elevate2.sql deleted" -ForegroundColor Green
       }
else 
    {}
Remove-Item -Path "C:\temp\Qlik_Sense_setup.exe" -Force
Write-Host "Installer deleted" -ForegroundColor Green
Remove-Item -Path "C:\Program Files\Qlik\Sense\Repository\PostgreSQL\9.6\bin\servicecluster.sql" -Force
Write-Host "servicecluster.sql deleted" -ForegroundColor Green
Remove-Item -Path "C:\Temp\spc.cfg" -Force
Write-Host "spc.cfg deleted"