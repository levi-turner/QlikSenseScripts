# Define your tenant URL
$tenant = Get-Content -Path ..\secrets\qcs-tenant.txt

# Define your API key
$apikey = Get-Content -Path ..\secrets\qcs-api_key.txt

# Dummy value for the headers
$hdrs = @{}

# Add in the API key to the headers
$hdrs.Add("Authorization","Bearer $($apikey)")

# Handle TLS 1.2 only environments
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12'

$bodyLines = '{"appId":"3d44f817-2c51-4ccd-a3b3-c3c501daf9e4"}'

# Send the file to QCS; defaults to personal files
Invoke-RestMethod -Uri "https://$($tenant)/api/v1/reloads" -Body $bodyLines -Method Post -Headers $hdrs
