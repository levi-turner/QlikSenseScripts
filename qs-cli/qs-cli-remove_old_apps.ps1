#Requires -Modules Qlik-Cli
Connect-Qlik >> $null
$InactivityThreshold=7
$createDate = (Get-Date).AddDays(-$InactivityThreshold).GetDateTimeFormats()[45]
Get-QlikApp -filter "createdDate lt '$createDate'" | Remove-QlikApp