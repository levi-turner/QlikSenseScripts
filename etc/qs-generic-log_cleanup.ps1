#--------------------------------------------------------------------------------------------------------------------------------
#
# Script Name: qlik_sense_qlik_support_log_cleanup.ps1
# Description: Cleanup the Qlik Sense logs on Support VMs
# 					
#   Version     Date        Author          Change Notes
#   0.1         2018-01-06  Levi Turner     Initial Version
# TODO:
#   N/A
# 
#--------------------------------------------------------------------------------------------------------------------------------

# Specify the age threshold which you want to keep
# e.g. 60 would move all logs older than 60 days
$days = "45"

# Usage https://technet.microsoft.com/en-us/library/cc733145(v=ws.11).aspx
# /e applies to files and subdirectories in the path
# /mov moves the files
$option1 = "/mov"
$option2 = "/e"

# Path of Qlik Sense Logs, typically the Archived Logs
$source = "C:\QlikShare\ArchivedLogs"

# Path of where you want the log files moved
$dest = "C:\OldLogs"

# Remove logs y/n
$removelogs = "y"

#Checking to see if the $dest path exists, else create it
if(!(Test-Path -Path $dest )){
    New-Item -ItemType directory -Path $dest
}

# Get initial start time for benchmarking
# $startTime = (Get-Date)

# Passing the current directory for log creation; performance improvement
# Start core robocopy call
$scriptDir = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
& robocopy $source $dest $option1 $option2 /MINAGE:$days /LOG:$scriptDir\robolog.log /MT

# Get end time for benchmarking
# $endTime = (Get-Date)

# Calculate execution time for benchmarking
# $ElapsedTime = (($endTime-$startTime).TotalSeconds)
# Write execution time for benchmarking
# Write-Host "Duration: $ElapsedTime"
# Deletes files if $removelogs = y
If ($removelogs -eq 'y') {Remove-Item $dest -Force -Recurse}
Else {"Files moved"}