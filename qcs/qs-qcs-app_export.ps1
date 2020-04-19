
# Define your tenant URL
$tenant = Get-Content -Path ..\secrets\qcs-tenant.txt

# Define your API key
$apikey = Get-Content -Path ..\secrets\qcs-api_key.txt

# Define your app ID
$appid = '9d7f481b-18c7-41c3-839d-1cd3392a07fb'

# Dummy value for the headers
$hdrs = @{}

# Add in the API key to the headers
$hdrs.Add("Authorization","Bearer $($apikey)")

# Handle TLS 1.2 only environments
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12' 

# Get the App Info
$app = Invoke-WebRequest -Method Get -Uri "https://$($tenant)/api/v1/apps/$($appid)" -Headers $hdrs
$app = $app.Content | ConvertFrom-Json

# Request the Export
# URI of temp path for download is $exportrequest.Headers.Location
$exportrequest = Invoke-WebRequest -Method Post -Uri "https://$($tenant)/api/v1/apps/$($appid)/export" -Headers $hdrs

# Set to our download location and request the app
Set-Location C:\Temp
Invoke-RestMethod -Uri "https://$($tenant)$($exportrequest.Headers.Location)" -Headers $hdrs -Method Get -OutFile .\$($app.attributes.name).qvf