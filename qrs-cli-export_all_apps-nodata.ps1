#Requires -Modules Qlik-Cli
Connect-Qlik
$apps = Get-QlikApp
Set-Location C:\Temp
Foreach ($app in $apps) {
    Export-QlikApp -id $app.id -filename "$($app.name).qvf" -SkipData:$true
}