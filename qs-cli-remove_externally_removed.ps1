#Requires -Modules Qlik-Cli
Connect-Qlik
Get-QlikUser -full | where {$_.removedExternally -eq "True"} | Remove-QlikUser