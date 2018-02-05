#--------------------------------------------------------------------------------------------------------------------------------
#
# Script Name:  qlik_sense_update_max_quota.ps1
# Description:  Update the file size limit inside of Qlik Sense
# Dependencies: Qlik-Cli
# 					
#   Version     Date        Author          Change Notes
#   0.1         2018-01-07  Levi Turner     Initial Version
# 
# CAUTION:     Setting this value lower than existing apps with attached content
#              will cause apps to error on duplication (and likely export)
# TODO:
#   Robustly handle the inputs
#     Conversion does not work
#     Error handling the inputs (ifs for 200 vs. 200MB)
#--------------------------------------------------------------------------------------------------------------------------------

# Get desired size inputs
$maxFileSize = Read-Host -Prompt 'Input the maximum file size in MB (e.g. 200MB)'
$maxLibrarySize = Read-Host -Prompt 'Input the maximum total attached size in MB (e.g. 200MB)'
<# 
# Non Working Conversion (concat issues)
$maxFileSize = ToString($maxFileSize) + 'MB'
$maxLibrarySize = $maxFileSize + 'MB'
#>

# Convert to bytes
$maxFileSizeValue = $maxFileSize/1
$maxLibrarySizeValue= $maxLibrarySize/1

# Connect to Qlik site
$myFQDN=(Get-WmiObject win32_computersystem).DNSHostName+"."+(Get-WmiObject win32_computersystem).Domain
$myFQDN = $myFQDN.ToLower()
Connect-Qlik -computername $myFQDN -UseDefaultCredentials

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
$MaxQuota | % {if($_.schemaPath -eq 'AppContentQuota'){$_.maxLibrarySize='209,715,200'}}

# Convert to JSON for PUT's body
$MaxQuota = $MaxQuota | ConvertTo-Json

# Inject in the changed values
Invoke-QlikPut -path /qrs/appcontentquota/$MaxQuotaID -body $MaxQuota