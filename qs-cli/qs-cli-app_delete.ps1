Connect-Qlik
$appstodelete = Import-Csv .\todelete.csv
#------------------------------------------------------------------------------------
# Format of todelete.csv:
# AppId
# b398c07c-61b5-480b-9eb0-ce4f13825145
# 9f0953d8-def4-4016-bea8-4d0c5ea2fd20
#------------------------------------------------------------------------------------

# Set the directory to store the files to
Set-Location C:\Temp
Foreach ($app in $appstodelete) {
    Write-Host $app.AppId is being exported
    # file will be written as bar and not bar.qvf ¯\_(ツ)_/¯
    Export-QlikApp -id $app.AppId -filename $(Get-QlikApp -id $app.AppId).name -SkipData:$true
    Write-Host $app.AppId is being Deleted
    Remove-QlikApp -id $app.AppId
}
