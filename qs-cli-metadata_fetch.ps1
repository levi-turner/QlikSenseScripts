#Requires -Modules Qlik-Cli
$Data = Get-Content C:\ProgramData\Qlik\Sense\Host.cfg
$FQDN = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($($Data)))
Connect-Qlik -ComputerName https://$($FQDN):443 -UseDefaultCredentials
$opsmon = Get-QlikApp -filter "name eq 'Operations Monitor'"
Invoke-QlikGet -path https://$($FQDN)/api/v1/apps/$($opsmon.id)/data/metadata