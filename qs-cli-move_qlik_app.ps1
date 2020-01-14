#Requires -Modules Qlik-Cli

# Connect to the site
Connect-Qlik

# Raw mode to support the original date format
$rawoutput=$true

# Get the App
$app = Get-QlikApp -filter "name eq 'foo'" -full

# Get the stream
$newstream = Get-QlikStream -filter "name eq 'exampleStream2'"

# Replace the app's stream and id elements
$app.stream | Add-Member id $newstream.id -Force
$app.stream | Add-Member name $newstream.name -Force

# Convert the app's record to JSON
$appjson= $app | ConvertTo-Json -Compress -Depth 10

# Put the modifed JSON to replace the app's information
Invoke-QlikPut -path /qrs/app/$($app.id) -body $appjson