#--------------------------------------------------------------------------------------------------------------------------------
#
# Script Name: qlik_sense_pwd_change.ps1
# Description: Change the password for a Qlik Sense Service account
# Dependency: Qlik-Cli (https://github.com/ahaydon/Qlik-Cli)
# 					
#   Version     Date        Author          Change Notes
#   0.1         2018-01-04  Levi Turner     Initial Version
#   0.2         2018-01-19  Levi Turner     Validation
#   0.2         2018-06-20  Levi Turner     Adding Admin rights catch + loop for QRS uptime
#   0.3         2020-04-18  Levi Turner     Change to loop
#
#--------------------------------------------------------------------------------------------------------------------------------
#Requires -Modules Qlik-Cli
# Admin catch
If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).
IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Warning "You do not have Administrator rights to run this script!`nPlease re-run this script as an Administrator!"
    Break
}

# Get new inputs

$Username = Read-Host -Prompt 'Input the username (DOMAIN\USERID format)'
$Password = Read-Host -Prompt 'Input the  new password'

# Warn of service stop

Write-Host "Qlik Sense Services will now stop" -ForegroundColor Green

# Stop all Qlik Sense Services

Get-Service QlikSenseSchedulerService -ComputerName localhost | Stop-Service
Get-Service QlikSenseEngineService -ComputerName localhost | Stop-Service
Get-Service QlikSensePrintingService -ComputerName localhost | Stop-Service
Get-Service QlikSenseProxyService -ComputerName localhost | Stop-Service
Get-Service QlikSenseServiceDispatcher -ComputerName localhost | Stop-Service
Get-Service QlikSenseRepositoryService -ComputerName localhost | Stop-Service
Get-Service QlikLoggingService -ComputerName localhost | Stop-Service
Get-Service QlikSenseRepositoryDatabase -ComputerName localhost | Stop-Service

# Change password

sc.exe config "QlikSenseRepositoryService" obj= "$Username" password= "$Password"
sc.exe config "QlikSenseServiceDispatcher" obj= "$Username" password= "$Password"
sc.exe config "QlikSenseProxyService" obj= "$Username" password= "$Password"
sc.exe config "QlikSenseSchedulerService" obj= "$Username" password= "$Password"
sc.exe config "QlikSenseEngineService" obj= "$Username" password= "$Password"
sc.exe config "QlikLoggingService" obj= "$Username" password= "$Password"
sc.exe config "QlikSensePrintingService" obj= "$Username" password= "$Password"

Write-Host "Password changed" -ForegroundColor Green
Write-Host "Qlik Sense Services will now start" -ForegroundColor Green

Get-Service QlikSenseRepositoryDatabase -ComputerName localhost | Start-Service
Get-Service QlikLoggingService -ComputerName localhost | Start-Service
Get-Service QlikSenseRepositoryService -ComputerName localhost | Start-Service
Get-Service QlikSenseSchedulerService -ComputerName localhost | Start-Service
Get-Service QlikSenseServiceDispatcher -ComputerName localhost | Start-Service
Get-Service QlikSenseProxyService -ComputerName localhost | Start-Service
Get-Service QlikSensePrintingService -ComputerName localhost | Start-Service
Get-Service QlikSenseEngineService -ComputerName localhost | Start-Service
Get-Service QlikSenseSchedulerService -ComputerName localhost | Start-Service

# Catch for service start failure
$qpsservicecatch = ''
    Do {
        if($qpsservicecatch.status -eq 'Running') {Write-Host "Qlik Sense Proxy Service Running"}
        else{
            Write-Host "Qlik Sense Proxy Service Initializing" -ForegroundColor Green
            start-sleep 5
            $qpsservicecatch =Get-Service QlikSenseProxyService -ComputerName localhost
        }
    }
    Until($qpsservicecatch.status -eq 'Running')  
    

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

# Begin Qlik CLI work

# Gets the configured hostname from the host.cfg file
$Data = Get-Content C:\ProgramData\Qlik\Sense\Host.cfg
# Convert the base64 encoded install name for Sense to UTF data
$FQDN = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($($Data)))

# Connect to Qlik-CLI

Do {
        
    if($($qpsalive.value) -eq 'true') {Write-Host "Qlik Sense Proxy is alive"}
    else{
    Write-Host "Qlik Sense Proxy is NOT alive" -ForegroundColor Green
    start-sleep 5
    Connect-Qlik -ComputerName https://$($FQDN):4242 -Username INTERNAL\sa_api
    $qpsalive = Invoke-QlikGet -path https://$($FQDN):4243/qps/alive
    }
}
Until($($qpsalive.value) -eq 'true')

# Begin QRS alive catch

$qrscatch = ''
Do {
        
    if(!$qrscatch.id) {Write-Host "Qlik Sense Repository is available for API Calls"}
    else{
    Write-Host "Qlik Sense Repository is NOT alive" -ForegroundColor Green
    start-sleep 5
    $qrscatch = Invoke-QlikGet -path "/qrs/dataconnection/full?filter=(name eq 'monitor_apps_REST_app')"
    }
}
Until(!$qrscatch.id)

# Needed to handle the dates in the JSON responses
$rawoutput=$true

$dataConnections = Invoke-QlikGet -path "/qrs/dataconnection/full?filter=(name sw 'monitor_apps_REST')"

foreach ($dataConnection in $dataConnections) {
    $dataConnectionBody = Invoke-QlikGet -path /qrs/dataconnection/$($dataConnection.id)
    $dataConnectionBody | Add-Member Password $Password -Force
    $dataConnectionBody = $dataConnectionBody | ConvertTo-Json
    Invoke-QlikPut -path https://$($FQDN):4242/qrs/dataconnection/$($dataConnection.id) -body $dataConnectionBody | Out-Null
}