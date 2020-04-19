#Requires -Modules Qlik-Cli
Connect-Qlik | Out-Null
$apps = Get-QlikApp
Set-Location C:\tmp\foo
$counter = 0
Foreach ($app in $apps) {
    ++$counter
    Export-QlikApp -id $app.id -filename "$($app.name).qvf" -SkipData:$true
    Write-Host "$($counter) of $($apps.Count) Exported"
}