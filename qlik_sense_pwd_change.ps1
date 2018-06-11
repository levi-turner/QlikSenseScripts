#--------------------------------------------------------------------------------------------------------------------------------
#
# Script Name: qlik_sense_pwd_change.ps1
# Description: Change the password for a Qlik Sense Service account
# Dependency: Qlik-Cli (https://github.com/ahaydon/Qlik-Cli)
# 					
#   Version     Date        Author          Change Notes
#   0.1         2018-01-04  Levi Turner     Initial Version
#   0.2         2018-01-19  Levi Turner     Validation
#
#--------------------------------------------------------------------------------------------------------------------------------

# Get new inputs

$Username = Read-Host -Prompt 'Input the username (DOMAIN\USERID format)'
$Password = Read-Host -Prompt 'Input the  new password'

# Warn of service stop

Write-Host "Qlik Sense Services will now stop" -ForegroundColor Green
Read-Host "Press Enter to continue"

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
Read-Host "Press Enter to continue"

Get-Service QlikSenseRepositoryDatabase -ComputerName localhost | Start-Service
Get-Service QlikLoggingService -ComputerName localhost | Start-Service
Get-Service QlikSenseRepositoryService -ComputerName localhost | Start-Service
Get-Service QlikSenseSchedulerService -ComputerName localhost | Start-Service
Get-Service QlikSenseServiceDispatcher -ComputerName localhost | Start-Service
Get-Service QlikSenseProxyService -ComputerName localhost | Start-Service
Get-Service QlikSensePrintingService -ComputerName localhost | Start-Service
Get-Service QlikSenseEngineService -ComputerName localhost | Start-Service
Get-Service QlikSenseSchedulerService -ComputerName localhost | Start-Service

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
start-sleep 50

# Begin Qlik CLI work

# Transform the hostname to lower for Connect-Qlik function
#$myFQDN=(Get-WmiObject win32_computersystem).DNSHostName+"."+(Get-WmiObject win32_computersystem).Domain
#$myFQDN = $myFQDN.ToLower()

# Gets the configured hostname from the host.cfg file
$Data = Get-Content C:\ProgramData\Qlik\Sense\Host.cfg
# Convert the base64 encoded install name for Sense to UTF data
$FQDN = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($($Data)))

# Connect to Qlik-CLI
Connect-Qlik -ComputerName https://$($FQDN):4242 -Username INTERNAL\sa_api

# Begin work on the monitor_apps_REST_app data connection
# Needed to handle the dates in the JSON responses
$rawoutput=$true

# Not quite working as of yet $RESTapp = Get-QlikDataConnection -filter "name eq 'monitor_apps_rest_app'"
# Get the ID of the Data Connection
$RESTapp = Invoke-QlikGet -path "/qrs/dataconnection/full?filter=(name eq 'monitor_apps_REST_app')"

# Filter out the ID value for later GET
$RESTappID = $RESTapp.id

# GET the DataConnection JSON
$RESTappDC = Invoke-QlikGet -path /qrs/dataconnection/$RESTappID


# $RESTappDC | % {if($_.qname -eq 'monitor_apps_REST_app'){$_.Password='$($Password)'}}
# Alternative approach $RESTappDC | Add-Member Password '$($Password)'

# Swap the password out in the JSON
$RESTappDC | Add-Member Password $Password -Force

# Convert to actual JSON
$RESTappDC = $RESTappDC | ConvertTo-Json

# PUT in the new password
Invoke-QlikPut -path https://$($myFQDN):4242/qrs/dataconnection/$RESTappID -body $RESTappDC

# Repeat for monitor_apps_REST_appobject
$RESTAppObject = Invoke-QlikGet -path "/qrs/dataconnection/full?filter=(name eq 'monitor_apps_REST_appobject')"
$RESTAppObjectID = $RESTAppObject.id
$RESTAppObjectDC = Invoke-QlikGet -path /qrs/dataconnection/$RESTAppObjectID
$RESTAppObjectDC | Add-Member Password $Password -Force
$RESTAppObjectDC = $RESTAppObjectDC | ConvertTo-Json
Invoke-QlikPut -path https://$($myFQDN):4242/qrs/dataconnection/$RESTAppObjectID -body $RESTAppObjectDC

# Repeat for monitor_apps_REST_event
$RESTEvent = Invoke-QlikGet -path "/qrs/dataconnection/full?filter=(name eq 'monitor_apps_REST_event')"
$RESTEventID = $RESTEvent.id
$RESTEventDC = Invoke-QlikGet -path /qrs/dataconnection/$RESTEventID
$RESTEventDC | Add-Member Password $Password -Force
$RESTEventDC = $RESTEventDC | ConvertTo-Json
Invoke-QlikPut -path https://$($myFQDN):4242/qrs/dataconnection/$RESTEventID -body $RESTEventDC

# Repeat for monitor_apps_REST_license_access
$RESTLicenseAccess = Invoke-QlikGet -path "/qrs/dataconnection/full?filter=(name eq 'monitor_apps_REST_license_access')"
$RESTLicenseAccessID = $RESTLicenseAccess.id
$RESTLicenseAccessDC = Invoke-QlikGet -path /qrs/dataconnection/$RESTLicenseAccessID
$RESTLicenseAccessDC | Add-Member Password $Password -Force
$RESTLicenseAccessDC = $RESTLicenseAccessDC | ConvertTo-Json
Invoke-QlikPut -path https://$($myFQDN):4242/qrs/dataconnection/$RESTLicenseAccessID -body $RESTLicenseAccessDC

# Repeat for monitor_apps_REST_license_login
$RESTLicenseLogin = Invoke-QlikGet -path "/qrs/dataconnection/full?filter=(name eq 'monitor_apps_REST_license_login')"
$RESTLicenseLoginID = $RESTLicenseLogin.id
$RESTLicenseLoginDC = Invoke-QlikGet -path /qrs/dataconnection/$RESTLicenseLoginID
$RESTLicenseLoginDC | Add-Member Password $Password -Force
$RESTLicenseLoginDC = $RESTLicenseLoginDC | ConvertTo-Json
Invoke-QlikPut -path https://$($myFQDN):4242/qrs/dataconnection/$RESTLicenseLoginID -body $RESTLicenseLoginDC

# Repeat for monitor_apps_REST_license_user
$RESTLicenseUser = Invoke-QlikGet -path "/qrs/dataconnection/full?filter=(name eq 'monitor_apps_REST_license_user')"
$RESTLicenseUserID = $RESTLicenseUser.id
$RESTLicenseUserDC = Invoke-QlikGet -path /qrs/dataconnection/$RESTLicenseUserID
$RESTLicenseUserDC | Add-Member Password $Password -Force
$RESTLicenseUserDC = $RESTLicenseUserDC | ConvertTo-Json
Invoke-QlikPut -path https://$($myFQDN):4242/qrs/dataconnection/$RESTLicenseUserID -body $RESTLicenseUserDC

# Repeat for monitor_apps_REST_task
$RESTTask = Invoke-QlikGet -path "/qrs/dataconnection/full?filter=(name eq 'monitor_apps_REST_task')"
$RESTTaskID = $RESTTask.id
$RESTTaskDC = Invoke-QlikGet -path /qrs/dataconnection/$RESTTaskID
$RESTTaskDC | Add-Member Password $Password -Force
$RESTTaskDC = $RESTTaskDC | ConvertTo-Json
Invoke-QlikPut -path https://$($myFQDN):4242/qrs/dataconnection/$RESTTaskID -body $RESTTaskDC

# Repeat for monitor_apps_REST_user
$RESTUser = Invoke-QlikGet -path "/qrs/dataconnection/full?filter=(name eq 'monitor_apps_REST_user')"
$RESTUserID = $RESTUser.id
$RESTUserDC = Invoke-QlikGet -path /qrs/dataconnection/$RESTUserID
$RESTUserDC | Add-Member Password $Password -Force
$RESTUserDC = $RESTUserDC | ConvertTo-Json
Invoke-QlikPut -path https://$($myFQDN):4242/qrs/dataconnection/$RESTUserID -body $RESTUserDC