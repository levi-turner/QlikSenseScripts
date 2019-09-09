#Requires -Modules Qlik-Cli
Connect-Qlik
Get-QlikUser -filter "userid eq 'test@test'" | Update-QlikUser -customProperties UserCustomProperty=foo