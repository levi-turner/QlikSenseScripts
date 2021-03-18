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
$body = $jsonDoc | ConvertTo-Json -Depth 4 | % { $_ -replace '"', '\"' }

qlik raw POST v1/invite --body $body
