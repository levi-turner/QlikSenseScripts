#Requires -Modules Qlik-Cli

[System.IO.FileInfo]$SourceApp = "C:\Temp\exampleApp.qvf"
$ID = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"

Connect-Qlik | Out-Null
# Figure out where the appimport folder is; we need to place the app here
$QSServiceCluster = Get-QlikServiceCluster -full
# Store the apps folder
$CopyFolder1 = $QSServiceCluster.settings.sharedPersistenceProperties.appFolder
# Store the app import folder used in the /qrs/app/import/ call later
$CopyFolder2 = Invoke-QlikGet "/qrs/app/importfolder"
# Build the empty app entity with our arbitrary GUID
$App = @{
  "id"= $ID
  "name"= 'Arbitrary GUID'
}
$appjson = $App|ConvertTo-Json
# Copy the app from its source location to the Qlik share > Apps path with the target GUID
Copy-Item -Path $SourceApp.FullName -Destination "$($CopyFolder1)\$($app.id)"
# Copy the app from its source location to the app import folder
Copy-Item -Path $SourceApp.FullName -Destination "$($CopyFolder2)\$($SourceApp.Name)"
$FI = [System.IO.FileInfo]::new("$($CopyFolder1)\$($app.id).lock")
# Create a new blank .lock file for the app's target GUID
$null = $FI.Create()
# Create the dummy QRS app entity with the target GUID
Invoke-QlikPost -path "/qrs/app" -body $appjson | Out-Null

# Get the current user's UserID
$user = $env:UserName.ToLower()
# Get the current user's Domain
$domain = $env:UserDomain.ToLower()
# Get the ID used for the current user
$qlikuser = Get-QlikUser -filter "userid eq '$($user)' and userdirectory eq '$($domain)'"
# Build out a dummy script
$scriptjson = '
{
  "owner": {
    "id": "'
$scriptjson += $($qlikuser).id
$scriptjson += '",
  },
  "attributes": "eyJUeXBlIjoiQXBwU2NyaXB0T2JqZWN0IiwiRm9ybWF0IjoiZ3pqc29uIiwiVGl0bGUiOiIiLCJQYXJlbnRJZCI6InF2YXBwX2FwcHNjcmlwdCIsIklzVGVtcG9yYXJ5IjpmYWxzZSwiQ29udGVudEhhc2giOiJiL2t5Y0piZHdDOWJQU2ZTVW9mb0xRYU1FZ2xKU3J3UnhpbncrTVlNVEZNPSJ9",
  "objectType": "app_appscript",
  "app": {
    "id": "'
$scriptjson += $ID
$scriptjson += '",
  },
  "privileges": null,
  "engineObjectId": "qvapp_appscript",
  "contentHash": "P7_S!HF>$],<VT*3,VBIX+\"-+2#*J%P2=+QDPR-QU5",
  "schemaPath": "App.Object"
}'
# Create the dummy script
Invoke-QlikPost -path '/qrs/app/object' -body $scriptjson | Out-Null
# Replace the dummy app with the dummy script with the full app to get all the app's objects (sheets, stories, bookmarks, etc)
Invoke-QlikPost -path "/qrs/app/import/replace?targetappid=$($app.id)" -body "`"$($SourceApp.Name)`""  | Out-Null
# Clean up the staged QVF used on the import
Remove-Item -Path "$($CopyFolder2)\$($SourceApp.Name)"