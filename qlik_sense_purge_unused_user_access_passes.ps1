#--------------------------------------------------------------------------------------------------------------------------------
#
# Script Name: qlik_sense_purge_unused_user_access_passes.ps1
# Description: Remove the assigned user access passes of users who have not used the system in X days
# Dependency: Qlik-Cli (https://github.com/ahaydon/Qlik-Cli)
# 					
#   Version     Date        Author          Change Notes
#   0.1         2018-01-30  Levi Turner     Initial Version
#
#--------------------------------------------------------------------------------------------------------------------------------

$InactivityThreshold = Read-Host -Prompt 'Input the username date threshold for inactivity (e.g. 90)'


# Get date format for 90 days ago
$date = Get-Date
$date = $date.AddDays(-$InactivityThreshold)
$date = $date.ToString("yyyy/MM/dd")
$time = Get-Date
$time = $time.GetDateTimeFormats()[109]
$inactive = $date + ' ' + $time

# Connect to Qlik Sense
$myFQDN=(Get-WmiObject win32_computersystem).DNSHostName+"."+(Get-WmiObject win32_computersystem).Domain
$myFQDN = $myFQDN.ToLower()

# Connect to Qlik-CLI
Connect-Qlik -ComputerName $($myFQDN) 

function Remove-QlikUserAccessType {
  [CmdletBinding()]
  param (
    [parameter(Position=0,ValueFromPipelinebyPropertyName=$true)]
    [string]$id
  )

  PROCESS {
    return Invoke-QlikDelete -path "/qrs/license/useraccesstype/$id"
  }
}

Get-QlikUserAccessType -filter "createdDate lt '$inactive'" -full | Remove-QlikUserAccessType