#------------------------------------------------------------------------------------
#
# Script Name: qs-silentInstallation.ps1
# Description: This script will do a basic silent installation of Qlik Sense Enterprise September 2020
#               This script will:
#                   Install Qlik Sense
#                   Create a local share if using local storage
#               This script will _not_:
#                   Create needed users, i.e. service account
#                   Add service account to local admin group
#                   Configure firewall rules
#                   Post-Installation application configuration, examples:
#                       Apply license
#                       Apply third party SSL certificate
#                       Configure authorization (security rules)

# Configurable Variables
# Staging location. Installer present in this directory. Logs also written here.
$tempPath = 'C:\Temp\'
# Use local storage for the Qlik Share. If true, the local share will be created (C:\QlikShare). If false, the share (with needed permissions for the service account must be created ahead of time)
$localStorage = 'true'
$sharePath = '\\whatever\share'
# The Qlik Sense Service account.
$serviceUser = 'DOMAIN\svc_user_account'
# The Qlik Sense Service Account's password
$serviceUserPassword = 'MySecretServiceAccountPassword'
# The password to the postgres user used in the underlying PostgreSQL database used by Qlik Sense Enterprise
$postgresPassword = 'MyPostgresPassword'
# The password to the qliksenserepository user used in the underlying PostgreSQL database used by Qlik Sense Enterprise
$qliksenseRepositoryPwd = 'MyQlikSenseRepositoryPassword'

# Admin rights catch
If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).
IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Warning "You do not have Administrator rights to run this script!`nPlease re-run this script as an Administrator!"
    Break
}

# Create Share Path

if ($localStorage) {
    Set-Location -Path C:\
    if (Test-Path C:\QlikShare) {
        Write-Host "C:\QlikShare already exists." -ForegroundColor Green
   } else {
       Write-Host "Creating QlikShare directory for Shared Persistence Storage" -ForegroundColor Green
       New-Item -Name QlikShare -ItemType directory
   }
   $currentUser = $env:UserDomain + '\' + $env:UserName
   # Create SMB Share
    if(!(Get-SMBShare -Name QlikShare -ea 0)){
        New-SmbShare -Name "QlikShare" -Path "C:\QlikShare" -FullAccess "$($currentUser)", "$($serviceUser)" | Out-Null
        Write-Host "Creating QlikShare SMB Share for Shared Persistence Storage" -ForegroundColor Green
    }
} else {
    # $localStorage is false
}

if (Test-Path C:\temp\spc.cfg) {
    Write-Host "Removing previously staged Shared Persistence Configuration" -ForegroundColor Green
    Remove-Item -Path "C:\temp\spc.cfg" -Force
} else {}


# Create spc.cfg
Set-Location -Path C:\Temp

if ($localStorage) {
    $SPShare = '\\' + $($env:computername) + '\QlikShare'
    }
} else {
    $SPShare = $sharePath
}

$filePath = "C:\Temp\spc.cfg" # Set the File Name
$XmlWriter = New-Object System.XMl.XmlTextWriter($filePath,$Null) # Create The Document
$xmlWriter.Formatting = "Indented" # Set The Formatting
$xmlWriter.Indentation = "4"
$xmlWriter.WriteStartDocument() # Write the XML Decleration
$xmlWriter.WriteStartElement("SharedPersistenceConfiguration") # Write Root Element
$xmlWriter.WriteElementString("DbUserName","qliksenserepository") # <-- Begin writing the XML file
$xmlWriter.WriteElementString("DbUserPassword","$($qliksenseRepositoryPwd)")
$xmlWriter.WriteElementString("DbHost","localhost")
$xmlWriter.WriteElementString("DbPort","4432")
$xmlWriter.WriteElementString("RootDir","$($SPShare)")
$xmlWriter.WriteElementString("StaticContentRootDir","$($SPShare)" + "\StaticContent")
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

# Unblock the EXE, usually unneeded
Unblock-File .\Qlik_Sense_setup.exe
# Silent install > do not start services
Write-Host "Qlik Sense will be installed" -ForegroundColor Green
Start-Process .\Qlik_Sense_setup.exe "-s userwithdomain=$($serviceUser) userpassword=$($serviceUserPassword) dbpassword=$($postgresPassword) sharedpersistenceconfig=C:\Temp\spc.cfg accepteula=1 hostname=$($env:ComputerName)" -wait
Write-Host "Qlik Sense Installed" -ForegroundColor Green

# Start services
Get-Service QlikSenseRepositoryDatabase -ComputerName localhost | Start-Service
Get-Service QlikSenseServiceDispatcher -ComputerName localhost | Start-Service
Get-Service QlikSenseRepositoryService -ComputerName localhost | Start-Service
Get-Service QlikSenseProxyService -ComputerName localhost | Start-Service
Get-Service QlikSensePrintingService -ComputerName localhost | Start-Service
Get-Service QlikSenseEngineService -ComputerName localhost | Start-Service
Get-Service QlikSenseSchedulerService -ComputerName localhost | Start-Service

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

# Artificial Sleep
start-sleep 10
Write-Host "Qlik Sense Enterprise initialized"
