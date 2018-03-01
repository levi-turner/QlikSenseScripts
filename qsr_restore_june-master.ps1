#------------------------------------------------------------------------------------
#
# Script Name: qsr_restore_sept_nov.ps1
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
#   Version     Date        Author          Change Notes
#   0.1         2017-12-20  Levi Turner     Initial Version
#   0.2         2017-12-20  Levi Turner     Switched to Get-Service method for service start / stop over net start / stop
#   0.3         2017-12-27  Levi Turner     Powershell does not like launching command line arguments directly, it seems
#   0.4         2018-01-02  Levi Turner     pgpass added for the .SQLs
#                                           Qlik Cli invocation to handle creating the user record
#   0.5         2018-01-02  Levi Turner     Added pauses. Clean run through
#   0.6         2018-01-10  Levi Turner     If-Exists checks / Sept/Nov Toggle
#   0.7         2018-02-20  Levi Turner     Clean up logging
#   0.8         2018-02-28  Levi Turner     Implemented the direct QRS call (adds support for Forms auth on default VP)
#   0.9         2018-02-28  Levi Turner     Cleaned up the QRS initialization logic to search for .LOG rather than hardcoded number
#
# TODO:
#   Toggle Internal (copy) vs. External (wget / build) [Long-term]
#   Remove previously staged files (Remove-Item .\foo.bar -Force)
#   Remove the .pgpass method (https://github.com/braathen/qlik-snapshot/blob/master/Qlik-Snapshot.psm1 seems to imply another way)
#   Handle versions better to extend support into 2018 release
#       With this enhancement; consolodate June and Sept/Nov scripts
#------------------------------------------------------------------------------------

# Stage the install files locally
Set-Location /
if (Test-Path C:\Temp) {
     Write-Output "C:\Temp already exists."
} else {
    Write-Output "Creating Temp directory for staging files"
    mkdir Temp
}

# wget https://da3hntz84uekx.cloudfront.net/QlikSense/11.24/0/_MSI/Qlik_Sense_setup.exe -OutFile Qlik_Sense_setup.exe

# Grab relevant version of Qlik Sense

if (Test-Path C:\temp\Qlik_Sense_setup.exe) {
    Write-Output "Qlik Sense already downloaded."
} else {
    Copy-Item "\\Dropzoneqvcloud\Dropzone\Applications\Qlik Sense\2017-06\Qlik_Sense_setup.exe" C:\temp\Qlik_Sense_setup.exe
    Write-Output "Qlik_Sense_setup.exe staged"
}


if (Test-Path C:\temp\spc.cfg) {
    Write-Output "Qlik Sense SPC Config present."
} else {
    Copy-Item "\\Dropzoneqvcloud\Dropzone\Private folders\LTU\automation\qsr_restore\spc.cfg" C:\temp\spc.cfg
}

if (Get-Module -ListAvailable -Name Qlik-Cli) {
    Write-Host "Qlik-Cli installed "
} else {
    Copy-Item "\\Dropzoneqvcloud\Dropzone\Private folders\LTU\automation\qsr_restore\install_qlik_cli.ps1" C:\temp\install_qlik_cli.ps1
    Set-Location Temp

    Write-Output "Explorer will launch, run install_qlik_cli.ps1"
    Read-Host "Press enter to continue with Qlik-CLI installation"
    
    explorer C:\temp

    Read-Host "Press any key after install_qlik_cli.ps1 is installed"
}

Set-Location C:\Temp
# Unblock the EXE, usually unneeded
Unblock-File .\Qlik_Sense_setup.exe
# Silent install > do not start services
Start-Process .\Qlik_Sense_setup.exe "-s userwithdomain=domain\Administrator userpassword=Password123! dbpassword=Password123! sharedpersistenceconfig=C:\Temp\spc.cfg skipstartservices=1" -wait

 Write-Output "Qlik Sense Installed"

# Start the Repo DB for .SQLs

Get-Service QlikSenseRepositoryDatabase -ComputerName localhost | Start-Service
Set-Location C:\Users\Administrator.DOMAIN.000\AppData\Roaming\
if (Test-Path C:\Users\Administrator.DOMAIN.000\AppData\Roaming\postgresql) {
    Write-Output ".pgpass directory already exists."
} else {
    mkdir postgresql
}
Set-Location postgresql
if (Test-Path C:\Users\Administrator.DOMAIN.000\AppData\Roaming\postgresql\pgpass.conf) {
    Write-Output ".pgpass already exists."
} else {
    Copy-Item "\\Dropzoneqvcloud\Dropzone\Private folders\LTU\automation\qsr_restore\pgpass.conf" C:\Users\Administrator.DOMAIN.000\AppData\Roaming\postgresql\pgpass.conf
}

Set-Location "C:\Program Files\Qlik\Sense\Repository\PostgreSQL\9.6\bin\"
# This will start up a new window, which inherits the password defined in the pgpass.conf copied above
$RootDir = get-childitem C:\
$TarList = $RootDir | where {$_.extension -eq ".tar"}
$TarList | format-table name
Start-Process .\pg_restore.exe "--host localhost --port 4432 --username postgres --dbname QSR c:\$TarList" -Wait

 Write-Output "Repository DB Restored"
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
    Write-Output "servicecluster.sql already exists."
} else {
    Copy-Item "\\Dropzoneqvcloud\Dropzone\Private folders\LTU\automation\qsr_restore\servicecluster.sql" "C:\Program Files\Qlik\Sense\Repository\PostgreSQL\9.6\bin\servicecluster.sql"
    Write-Output "Service Cluster Injection SQL staged"
}
Start-Process .\psql.exe "--host localhost --port 4432 -U postgres --dbname QSR -e -f repro_elevation.sql"

 Write-Output "Service Cluster injected"
 Read-Host "Press Enter to continue"

# Restore the hostname
$RestoreHostNameConfig = 'C:\Program Files\Qlik\Sense\Repository\Repository.exe.config'
(Get-Content $RestoreHostNameConfig) -replace '<add key="EnableRestoreHostname" value="false" />', '<add key="EnableRestoreHostname" value="true" />' | Set-Content $RestoreHostNameConfig

Write-Output "EnableRestoreHostname key modified"

# Start services to go into the QMC to create the user record
# TODO: Can this be handled via an API call to create a user?
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
        "Repository Still Initializing"
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

 Write-Output "Account created in QSR"
 Read-Host "Press Enter to continue"

# Elevation conditional
if (Test-Path "C:\Program Files\Qlik\Sense\Repository\PostgreSQL\9.6\bin\repro_elevation.sql") {
    Write-Output "servicecluster.sql already exists."
} else {
    Copy-Item "\\Dropzoneqvcloud\Dropzone\Private folders\LTU\automation\qsr_restore\repro_elevation.sql" "C:\Program Files\Qlik\Sense\Repository\PostgreSQL\9.6\bin\repro_elevation.sql"
    Write-Output "User elevation SQL staged"
}

Set-Location C:\"Program Files"\Qlik\Sense\Repository\PostgreSQL\9.6\bin
# Begin elevating the Admin account
Start-Process .\psql.exe "-h localhost -p 4432 -U postgres -d QSR -e -f repro_elevation.sql" -Wait

 Write-Output "Account elevated"
 Read-Host "Press Enter to continue"

# Cycle services to flush Repo cache
# Stop Services
Get-Service QlikSenseProxyService -ComputerName localhost | Stop-Service
Get-Service QlikSenseServiceDispatcher -ComputerName localhost | Stop-Service
Get-Service QlikSenseRepositoryService -ComputerName localhost | Stop-Service
Get-Service QlikSenseRepositoryDatabase -ComputerName localhost | Stop-Service
# Start services
Get-Service QlikSenseRepositoryDatabase -ComputerName localhost | Start-Service
Get-Service QlikSenseRepositoryService -ComputerName localhost | Start-Service
Get-Service QlikSenseSchedulerService -ComputerName localhost | Start-Service
Get-Service QlikSenseServiceDispatcher -ComputerName localhost | Start-Service
Get-Service QlikSenseProxyService -ComputerName localhost | Start-Service
Get-Service QlikSensePrintingService -ComputerName localhost | Start-Service
Get-Service QlikSenseEngineService -ComputerName localhost | Start-Service
Get-Service QlikSenseSchedulerService -ComputerName localhost | Start-Service