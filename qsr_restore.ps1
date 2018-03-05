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
#
# TODO:
#
#   Toggle Internal (copy) vs. External (wget / build) [Long-term]
#   Remove the .pgpass method 
#       (https://github.com/braathen/qlik-snapshot/blob/master/Qlik-Snapshot.psm1 seems to imply another way)
#
#------------------------------------------------------------------------------------

# Stage the install files locally
Set-Location /
if (Test-Path C:\Temp) {
     Write-Output "C:\Temp already exists."
} else {
    Write-Output "Creating Temp directory for staging files"
    mkdir Temp
}

# Toggle between June / Sept / Nov / Feb (untested)
# Undocumented 3.2
Write-Output "Next you will enter the Qlik Sense Version"
Write-Output "Enter the version in YYYY-MM format"
$QSVersion = Read-Host -Prompt 'Input Qlik Sense Build (e.g. 2017-06)'

if ($($QSVersion) -eq '2017-06') {
    Write-Output "This script will now silently install June 2017"
} elseif ($($QSVersion) -eq '2017-09') {Write-Output "This script will now silently install Sept 2017"}
  elseif ($($QSVersion) -eq '2017-11') {Write-Output "This script will now silently install Nov 2017"}
  elseif ($($QSVersion) -eq '2018-02') {Write-Output "This script will now silently install Feb 2018"}
  else 
    {Write-Output "Invalid/Unsupported build"
    exit
    }

# wget https://da3hntz84uekx.cloudfront.net/QlikSense/11.24/0/_MSI/Qlik_Sense_setup.exe -OutFile Qlik_Sense_setup.exe

# Grab relevant version of Qlik Sense

if (Test-Path C:\temp\Qlik_Sense_setup.exe) {
    Write-Output "Qlik Sense already downloaded."
} else {
    Copy-Item "\\Dropzoneqvcloud\Dropzone\Applications\Qlik Sense\$QSVersion\Qlik_Sense_setup.exe" C:\temp\Qlik_Sense_setup.exe
    Write-Output "Qlik_Sense_setup.exe staged"
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
#     Write-Output "Qlik Sense already downloaded."
# } else {
#     Invoke-WebRequest https://da3hntz84uekx.cloudfront.net/QlikSense/$build/0/_MSI/Qlik_Sense_setup.exe -OutFile C:\temp\Qlik_Sense_setup.exe
#     Write-Output "Qlik_Sense_setup.exe staged"
# }

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
Start-Process .\psql.exe "--host localhost --port 4432 -U postgres --dbname QSR -e -f servicecluster.sql"

 Write-Output "Service Cluster injected"
 Read-Host "Press Enter to continue"

# Restore the hostname

if ($($QSVersion) -eq '2017-06') {
    Write-Output "This script will not restore the Hostname for June 2017"
    $RestoreHostNameConfig = 'C:\Program Files\Qlik\Sense\Repository\Repository.exe.config'
    (Get-Content $RestoreHostNameConfig) -replace '<add key="EnableRestoreHostname" value="false" />', '<add key="EnableRestoreHostname" value="true" />' | Set-Content $RestoreHostNameConfig

    Write-Output "EnableRestoreHostname key modified"

} elseif ($($QSVersion) -eq '2017-09') {
    Write-Output "This script will not restore the Hostname for Sept 2017"
    Set-Location C:\"Program Files"\Qlik\Sense\Repository
    Start-Process  .\Repository.exe  "-bootstrap -standalone -restorehostname" -Wait

    Write-Output "Bootstrap run"
    Read-Host "Press Enter to continue"
}
  elseif ($($QSVersion) -eq '2017-11') {
      Write-Output "This script will not restore the Hostname for Nov 2017"
      Set-Location C:\"Program Files"\Qlik\Sense\Repository
    Start-Process  .\Repository.exe  "-bootstrap -standalone -restorehostname" -Wait

    Write-Output "Bootstrap run"
    Read-Host "Press Enter to continue"
    }
  elseif ($($QSVersion) -eq '2018-02') {
        Write-Output "This script will not restore the Hostname for Feb 2018"
        Set-Location C:\"Program Files"\Qlik\Sense\Repository
        Start-Process  .\Repository.exe  "-bootstrap -standalone -restorehostname" -Wait

        Write-Output "Bootstrap run"
        Read-Host "Press Enter to continue"
    }
  else 
    {Write-Output "Invalid/Unsupported build"
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

# Elevate the DOMAIN\Administrator account to being a RootAdmin
Connect-Qlik -Computername https://$($myFQDN):4242 -Username internal\sa_api
$ElevateUser = Get-QlikUser -filter "userdirectory eq 'DOMAIN'" -raw -full
$ElevateUserID = $ElevateUser.ID
Update-QlikUser -id $ElevateUserID -roles RootAdmin

# Elevation conditional
# if (Test-Path "C:\Program Files\Qlik\Sense\Repository\PostgreSQL\9.6\bin\repro_elevation.sql") {
#     Write-Output "repro_elevation.sql already exists."
# } else {
#     Copy-Item "\\Dropzoneqvcloud\Dropzone\Private folders\LTU\automation\qsr_restore\repro_elevation.sql" "C:\Program Files\Qlik\Sense\Repository\PostgreSQL\9.6\bin\repro_elevation.sql"
#     Write-Output "User elevation SQL staged"
# }

# Set-Location C:\"Program Files"\Qlik\Sense\Repository\PostgreSQL\9.6\bin
# Begin elevating the Admin account
# Start-Process .\psql.exe "-h localhost -p 4432 -U postgres -d QSR -e -f repro_elevation.sql" -Wait

 Write-Output "Account elevated"
 Read-Host "Press Enter to continue"

# Cycling not needed since revamping elevation to use QRS API
# #Cycle services to flush Repo cache
# #Stop Services
# Get-Service QlikSenseProxyService -ComputerName localhost | Stop-Service
# Get-Service QlikSenseServiceDispatcher -ComputerName localhost | Stop-Service
# Get-Service QlikSenseRepositoryService -ComputerName localhost | Stop-Service
# Get-Service QlikSenseRepositoryDatabase -ComputerName localhost | Stop-Service
# Start services
# Get-Service QlikSenseRepositoryDatabase -ComputerName localhost | Start-Service
# Get-Service QlikSenseRepositoryService -ComputerName localhost | Start-Service
# Get-Service QlikSenseSchedulerService -ComputerName localhost | Start-Service
Get-Service QlikSenseServiceDispatcher -ComputerName localhost | Start-Service
# Get-Service QlikSenseProxyService -ComputerName localhost | Start-Service
Get-Service QlikSensePrintingService -ComputerName localhost | Start-Service
Get-Service QlikSenseEngineService -ComputerName localhost | Start-Service
Get-Service QlikSenseSchedulerService -ComputerName localhost | Start-Service

Write-Output "Clean up activities"
Remove-Item -Path "C:\temp\Qlik_Sense_setup.exe" -Force
Write-Output "Installer deleted"
Remove-Item -Path "C:\Program Files\Qlik\Sense\Repository\PostgreSQL\9.6\bin\servicecluster.sql" -Force
Write-Output "servicecluster.sql deleted"
Remove-Item -Path "C:\Users\Administrator.DOMAIN.000\AppData\Roaming\postgresql\pgpass.conf" -Force
Write-Output ".pgpass deleted"
# Repository elevation no longer needed; handled via QRS API Calls
#Remove-Item -Path "C:\Program Files\Qlik\Sense\Repository\PostgreSQL\9.6\bin\repro_elevation.sql" -Force
#Write-Output "repro_elevation.sql deleted"