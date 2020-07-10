# Define your tenant URL
$tenant = Get-Content -Path ..\secrets\qcs-tenant.txt

# Define your API key
$apikey = Get-Content -Path ..\secrets\qcs-api_key.txt

# Dummy value for the headers
$hdrs = @{}
# Add in the API key to the headers
$hdrs.Add("Authorization","Bearer $($apikey)")
# Many thanks to https://stackoverflow.com/questions/36268925/powershell-invoke-restmethod-multipart-form-data
# Read the file
$filePath = 'C:\Temp\Random Data.qvf';

# Parse out the filename
$FileName = Split-Path $filePath -leaf

# Encode the file
$fileBytes = [System.IO.File]::ReadAllBytes($filePath);


$hdrs.Add("Content-Length","$($fileBytes.Length)")
$hdrs.Add("Content-Type","application/octet-stream")
# Handle TLS 1.2 only environments
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12'

# Send the file to QCS
$app = Invoke-RestMethod -Uri "https://$($tenant)/api/v1/apps/import?fallbackName=$FileName" -ContentType "application/octet-stream"  -Method Post -Headers $hdrs -InFile $filePath

# Construct the body of the items entity that we're creating from the response
$appbody = '{
    "name": "'
$appbody += $app.attributes.name
$appbody += '",
    "resourceAttributes": {
        "_resourcetype": "app",
        "id": "'
$appbody += $app.attributes.id
$appbody += '",
        "name": "'
$appbody += $app.attributes.name
$appbody += '",
        "ownerId": "'
$appbody += $app.attributes.ownerId
$appbody += '", 
        "thumbnail" : "'
$appbody += $app.attributes.thumbnail
$appbody += '"
    },
    "resourceType": "app",
    "resourceId": "'
    $appbody += $app.attributes.id
    $appbody += '",
    "resourceCreatedAt": "'
    $appbody += $app.attributes.createdDate
    $appbody +='",
    "ownerId": "'
    $appbody += $app.attributes.ownerId
    $appbody += '"}'

# Redo the headers
$hdrs = @{}
$hdrs.Add("Authorization","Bearer $($apikey)")
$hdrs.Add("Content-Type","application/javascript")

# Create the item
Invoke-RestMethod -Uri "https://$($tenant)/api/v1/items" -Method Post -Headers $hdrs -Body $appbody
