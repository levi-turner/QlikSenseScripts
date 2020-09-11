# Define your tenant URL
$tenant = Get-Content -Path ..\secrets\qcs-tenant.txt

# Define your API key
$apikey = Get-Content -Path ..\secrets\qcs-api_key.txt

# Dummy value for the headers
$hdrs = @{}
# Add in the API key to the headers
$hdrs.Add("Authorization","Bearer $($apikey)")
$hdrs.Add("content-type","application/json")

# Handle TLS 1.2 only environments
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12'

$body = '{"description":"123","expiry":"PT6H"}'

$newKey = Invoke-RestMethod -Method Post -Uri "https://$($tenant)/api/v1/api-keys" -Headers $hdrs -Body $body
