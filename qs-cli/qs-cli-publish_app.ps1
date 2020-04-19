#Requires -Modules Qlik-Cli
Connect-Qlik | Out-Null
$Streamid=Get-QlikStream -filter "(name eq 'My Stream')" | Select id
$Appid=Get-QlikApp -filter "(name eq 'My App')"
Publish-QlikApp -id $Appid.id -Stream $Streamid.id | Out-Null