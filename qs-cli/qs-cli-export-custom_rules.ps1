#Requires -Modules Qlik-Cli
Connect-Qlik | Out-Null
Get-QlikRule -filter "type eq 'custom' and category eq 'security'" -full -raw | ConvertTo-Json | Out-File C:\Temp\qlikrules.json