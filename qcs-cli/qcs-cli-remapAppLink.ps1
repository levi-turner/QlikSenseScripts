# Define the managed app ID (taken from the URL in the Hub)
$managedAppId = '11c9d613-c569-4b2b-9dd2-f5028db4f757'
# Define the new app ID (taken from the URL in the Hub) which will have a symbolic link to the managed app
$newAppId = '563b68ea-4e11-4420-9a8c-9a3cef618d64'
<# 
    Get all items in the environment
#>
$new_apps = qlik item ls --resourceType app --limit 100 --raw | ConvertFrom-Json;
$all_apps = $new_apps.data;
 
try { $next_path = [regex]::match($new_apps.links.next.href, '(?<=&next=)(?(?!&|$).)*').Value; }
catch { $next_path = $null }
 
WHILE ($next_path) {
    $new_apps = qlik item ls --resourceType app --limit 100 --next $next_path --raw | ConvertFrom-Json;
     
    try { $next_path = [regex]::match($new_apps.links.next.href, '(?<=&next=)(?(?!&|$).)*').Value; }
    catch { $next_path = $null }
 
    $all_apps += $new_apps.data;
}
# Store the managedApp's item record 
$managedItem = $all_apps | Where-Object {$_.resourceId -eq $($managedAppId)}
# Get the raw structure of the managed app's item
$managedItemRaw = qlik raw get v1/items/$($managedItem.id) | ConvertFrom-Json
# Insert the new pointer to the new app
$managedItemRaw.resourceAttributes.originAppId = $newAppId
# Convert the body to JSON with escapes
$managedItemRawJSON = $managedItemRaw | ConvertTo-Json | % { $_ -replace '"', '\"' }
# Adjust the _item_ record with the new pointer
qlik raw put v1/items/$($managedItem.id) --body $managedItemRawJSON
# Store the managedApp's app record
$managedAppRaw = qlik raw get v1/apps/$($managedAppId) | ConvertFrom-Json
# Insert the new pointer to the new app
$managedAppRaw.attributes.originAppId = $newAppId
# Convert the body to JSON with escapes
$managedAppRawJSON = $managedAppRaw | ConvertTo-Json | % { $_ -replace '"', '\"' }
# Adjust the _app_ record with the new pointer
qlik raw put v1/apps/$($managedAppId) --body $managedAppRawJSON
