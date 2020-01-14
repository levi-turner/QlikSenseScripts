#Requires -Modules Qlik-Cli
Connect-Qlik
Set-Location C:\Temp
$app = Import-QlikApp -file "exampleApp2.qvf" -name "Testing" -upload 
Write-Host "App $($app.name) with ID $($app.id) uploaded"
$stream = Get-QlikStream -filter "name eq 'Everyone'"
Write-Host "Stream $($stream.name) with ID $($stream.id) exists"
$app | Publish-QlikApp -stream Everyone
