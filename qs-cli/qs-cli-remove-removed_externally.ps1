#Requires -Modules Qlik-Cli
Connect-Qlik | Out-Null
Get-QlikUser -full | where {$_.removedExternally -eq "True"} | Remove-QlikUser