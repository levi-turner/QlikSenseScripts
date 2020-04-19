#Requires -Modules Qlik-Cli
Connect-Qlik | Out-Null
Set-Location C:\Temp
$app = Import-QlikApp -file "exampleApp.qvf" -name "Testing" -upload
$stream = Get-QlikStream -filter "name eq 'Everyone'"
$app | Publish-QlikApp -stream Everyone | Out-Null
