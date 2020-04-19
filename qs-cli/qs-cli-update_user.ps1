#Requires -Modules Qlik-Cli
Connect-Qlik | Out-Null
Get-QlikUser -filter "userid eq 'test@test'" | Update-QlikUser -customProperties UserCustomProperty=foo