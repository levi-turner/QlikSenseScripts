#Requires -Modules Qlik-Cli
# Connect to the site. Need to go over QPS. The API isn't exposed by the Repository
Connect-Qlik -UseDefaultCredentials
$app = Get-QlikApp -filter "name eq 'test'" -full
$newstream = Get-QlikStream -filter "name eq 'Everyone'"
$moveBody = '{"streamId":"'
$moveBody += $newstream.id
$moveBody += '","appName":"'
$moveBody += $app.name
$moveBody += '"}'
Invoke-QlikPut -path /api/hub/v1/apps/$($app.id)/move -body $moveBody | Out-Null