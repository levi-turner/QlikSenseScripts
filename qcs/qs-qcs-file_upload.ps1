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
$filePath = 'C:\Data\QVDs\Characters.qvd';

# Parse out the filename
$FileName = Split-Path $filePath -leaf

# Encode the file
$fileBytes = [System.IO.File]::ReadAllBytes($filePath);
$fileEnc = [System.Text.Encoding]::GetEncoding('UTF-8').GetString($fileBytes);

# Random boundary file for the request body
$boundary = [System.Guid]::NewGuid().ToString(); 
$LF = "`r`n";

# Construct the Request body
$bodyLines = ( 
    "--$boundary",
    "Content-Disposition: form-data; name=`"data`"; filename=`"$($fileName).qvd`"",
    "Content-Type: application/octet-stream$LF",
    "Data: $fileEnc",
    "--$boundary--$LF" 
) -join $LF

# Handle TLS 1.2 only environments
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12'

# Send the file to QCS
Invoke-RestMethod -Uri "https://$($tenant)/api/v1/qix-datafiles?name=Characters.qvd" -ContentType "multipart/form-data; boundary=`"$boundary`"" -Body $bodyLines -Method Post -Headers $hdrs