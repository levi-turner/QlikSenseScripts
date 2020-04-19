#Requires -Modules Qlik-Cli
Connect-Qlik -UseDefaultCredentials | Out-Null
$opsmon = Get-QlikApp -filter "name eq 'Operations Monitor'"
Invoke-QlikGet -path https://$($FQDN)/api/v1/apps/$($opsmon.id)/data/metadata