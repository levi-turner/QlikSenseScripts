#--------------------------------------------------------------------------------------------------------------------------------
#
# Script Name: qlik_sense_purge_unused_user_access_passes.ps1
# Description: Remove the assigned user access passes of users who have not used the system in X days
# Dependency: Qlik-Cli (https://github.com/ahaydon/Qlik-Cli)
# 					
#   Version     Date        Author          Change Notes
#   0.1         2018-01-30  Levi Turner     Initial Version
#   0.2         2018-03-06  Levi Turner     createdDate > lastUsed
#
#--------------------------------------------------------------------------------------------------------------------------------

#Requires -Modules Qlik-Cli

$InactivityThreshold = Read-Host -Prompt 'Input the username date threshold for inactivity (e.g. 90)'

# Get date format for 90 days ago
$date = Get-Date
$date = $date.AddDays(-$InactivityThreshold)
$date = $date.ToString("yyyy/MM/dd")
$time = Get-Date
$time = $time.GetDateTimeFormats()[109]
$inactive = $date + ' ' + $time

# Connect to Qlik-CLI
Connect-Qlik

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

Get-QlikUserAccessType -filter "lastUsed lt '$inactive'" -full | Remove-QlikUserAccessType