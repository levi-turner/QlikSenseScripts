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
Connect-Qlik | Out-Null

Get-QlikUserAccessType -filter "lastUsed lt '$inactive'" -full | Remove-QlikUserAccessType