$dayOfMonth = '18' # Target Date of the Month
$appId = '5e34dbc8-bc07-4377-906d-bb370853d731' # Target App's ID
$month = (Get-Date).Month # Get the Month, will be numeric, e.g. 6
$monthName = (Get-Culture).DateTimeFormat.GetMonthName($month) # Get the MonthName localized to the user, e.g. June
if ((Get-Date).day -eq $dayOfMonth) {
    Connect-Qlik | Out-Null # Connect to Qlik Sense
    $app = Get-QlikApp -id $appId # Get the Target App's record
    Copy-QlikApp -id $app.id -name "$($app.name) $monthName" | Publish-QlikApp -stream $app.stream.id | Out-Null
}