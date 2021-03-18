# Import list of emails
$emails = Get-Content -Path .\emails.txt
<# Example file structure:
foo@bar.com
foo2@bar.com
#>

# Build an array of emails
$subEmails = @()
foreach($email in $emails) {
    $subEmails += [PSCustomObject]@{
    'email'="$email";
    }
}
# Add that array fo emails to another array of invitees
$jsonDoc = [pscustomobject]@{
    invitees = $subEmails
}
# Build the JSON structure
$body = $jsonDoc | ConvertTo-Json -Depth 4

# Define your tenant URL
$tenant = Get-Content -Path ..\secrets\qcs-tenant.txt

# Define your API key
$apikey = Get-Content -Path ..\secrets\qcs-api_key.txt

# Dummy value for the headers
$hdrs = @{}
# Add in the API key to the headers
$hdrs.Add("Authorization","Bearer $($apikey)")
$hdrs.Add("content-type","application/json")

Invoke-RestMethod -Method Post -Uri "https://$($tenant)/api/v1/invite" -Headers $hdrs -Body $body
