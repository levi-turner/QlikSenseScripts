#Requires -Modules Qlik-Cli
Connect-Qlik | Out-Null
Get-QlikApp -filter "stream.name eq 'Monitoring Apps' and customProperties.value eq 'bar'" -full