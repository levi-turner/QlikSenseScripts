#Requires -Modules Qlik-Cli
Connect-Qlik | Out-Null
Get-QlikRule -filter "name eq 'foo'" | Update-QlikRule -disabled
