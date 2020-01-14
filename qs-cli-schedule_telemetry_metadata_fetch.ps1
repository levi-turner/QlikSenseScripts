#Requires -Modules Qlik-Cli

Connect-Qlik
# Using raw output to handle date formats
$rawoutput=$true
$operationalBody = '  {
    "nextExecution": "2018-10-25T13:30:26Z",
    "schemaPath": "SchemaEventOperational"
  }'
# Create the Schema Operational
$schemaOperational = Invoke-QlikPost -path /qrs/schemaeventoperational -body $operationalBody
$metadataFetchTask = Invoke-QlikGet -path "/qrs/externalprogramtask/full?filter=(name eq 'TelemetryDashboard-1-Generate-Metadata')"
$metadataFetchTask = Invoke-QlikGet -path /qrs/externalprogramtask/$($metadataFetchTask.id)
$eventBody = '{
    "createdDate": "2017-05-06T00:55:54.201Z",
    "modifiedDate": "2017-05-26T15:48:06.347Z",
    "modifiedByUserName": "INTERNAL\\sa_api",
    "timeZone": "America/New_York",
    "daylightSavingTime": 0,
    "startDate": "2018-10-25T13:30:26Z",
    "expirationDate": "9999-12-31T00:00:00",
    "schemaFilterDescription": [
      "* * - * * * * *"
    ],
    "incrementDescription": "0 0 1 0",
    "incrementOption": 2,
    "operational": {
    "id": "'
$eventbody += $($schemaOperational.id)
$eventBody += '",
    "createdDate": "2018-10-25T13:06:26.078Z",
    "modifiedDate": "2018-10-25T13:06:26.078Z",
    "modifiedByUserName": "INTERNAL\\sa_repository",
    "lastEventDate": "1753-01-01T00:00:00Z",
    "nextExecution": "2018-10-25T13:30:26Z",
    "timesTriggered": 0,
    "privileges": null,
    "schemaPath": "SchemaEventOperational"
  },
    "name": "Reload fetchmetadata.js",
    "enabled": true,
    "eventType": 0,
    "externalProgramTask": {
      "id": "'
$eventBody += $($metadataFetchTask.id)
$eventBody += '",
      "operational": {
        "id": "'
$eventBody += $($metadataFetchTask.operational.id)
$eventBody += '"},
      "name": "TelemetryDashboard-1-Generate-Metadata",
      "taskType": 1,
      "enabled": true,
      "taskSessionTimeout": 1440,
      "maxRetries": 0,
      "privileges": null
    },
    "userSyncTask": null,
    "reloadTask": null,
    "privileges": null,
    "schemaPath": "SchemaEvent"
  }'
Invoke-QlikPost -path "/qrs/schemaEvent" -body $eventBody
<# 
$changeownerapp = Get-QlikApp -filter "(name eq 'foo')" -full
$changeownerappID = $changeownerapp.id
$changeowneruser = Get-QlikUser -filter "(name eq 'sa_repository')" -full
#$changeowneruser = ($(Get-QlikUser -filter "(name eq 'sa_repository')" -full)) 
$changeownerapp.owner | Add-Member id $changeowneruser.id -Force
$changeownerapp.owner | Add-Member userId $changeowneruser.userId -Force
$changeownerapp.owner | Add-Member name $changeowneruser.name -Force
$changeownerapp.owner | Add-Member userDirectory $changeowneruser.userDirectory -Force
$changeownerappjson = $changeownerapp | ConvertTo-Json -Compress -Depth 10
Invoke-QlikPut -path /qrs/app/$changeownerappID -body $changeownerappjson
#>