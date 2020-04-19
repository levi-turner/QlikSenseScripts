# Get desired size inputs
$maxFileSize = Read-Host -Prompt 'Input the maximum file size in MB (e.g. 200MB)'
$maxLibrarySize = Read-Host -Prompt 'Input the maximum total attached size in MB (e.g. 200MB)'

# Convert to bytes
$maxFileSizeValue = $maxFileSize/1
$maxLibrarySizeValue= $maxLibrarySize/1

# Connect to Qlik site
Connect-Qlik | Out-Null

# Raw output, otherwise the dates get prettified
$rawoutput=$true

# Get Current Quota JSON
$MaxQuota = Invoke-QlikGet -path /qrs/appcontentquota/full

# Seperate out the ID for the subsequent PUT
$MaxQuotaID = $MaxQuota.id

# maxFileSize is the max file size for each individual file
# Unit is bytes
$MaxQuota | % {if($_.schemaPath -eq 'AppContentQuota'){$_.maxFileSize=$maxFileSizeValue}}

# maxLibrarySize is total space in an app for all files
# Unit is bytes
$MaxQuota | % {if($_.schemaPath -eq 'AppContentQuota'){$_.maxLibrarySize=$maxLibrarySizeValue}}

# Convert to JSON for PUT's body
$MaxQuota = $MaxQuota | ConvertTo-Json

# Inject in the changed values
Invoke-QlikPut -path /qrs/appcontentquota/$MaxQuotaID -body $MaxQuota | Out-Null