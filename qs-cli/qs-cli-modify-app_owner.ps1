#Requires -Modules Qlik-Cli
Connect-Qlik | Out-Null
$rawoutput=$true
$changeownerapp = Get-QlikApp -filter "(name eq 'foo')" -full
$changeownerappID = $changeownerapp.id
$changeowneruser = Get-QlikUser -filter "(name eq 'sa_repository')" -full
#$changeowneruser = ($(Get-QlikUser -filter "(name eq 'sa_repository')" -full)) 
$changeownerapp.owner | Add-Member id $changeowneruser.id -Force
$changeownerapp.owner | Add-Member userId $changeowneruser.userId -Force
$changeownerapp.owner | Add-Member name $changeowneruser.name -Force
$changeownerapp.owner | Add-Member userDirectory $changeowneruser.userDirectory -Force
$changeownerappjson = $changeownerapp | ConvertTo-Json -Compress -Depth 10
Invoke-QlikPut -path /qrs/app/$changeownerappID -body $changeownerappjson | Out-Null