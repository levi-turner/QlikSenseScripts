#Requires -Modules Qlik-Cli
Connect-Qlik
$Streamid=Get-QlikStream -filter "(name eq 'Monitoring apps')" | Select id
Write-Host $Streamid.id
$Appid=Get-QlikApp -filter "(name eq 'Log Monitor')"
Write-Host $Appid.id
Publish-QlikApp -id $Appid.id -Stream $Streamid.id