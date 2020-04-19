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

# Get the Storage Quota Info
$quota = Invoke-RestMethod -Method Get -Uri "https://$($tenant)/api/v1/qix-datafiles/quota" -Headers $hdrs
Write-Host ($($quota.maxSize)/1024/1024/1024) "GBs in quota"
Write-Host ($($quota.size)/1024/1024/1024) "GB used"
Write-Host ($($quota.size)/$($quota.maxSize)*100) "% of quota remaining"
