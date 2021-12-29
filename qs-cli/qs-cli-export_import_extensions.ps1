# This script will export an extension from a source environment and replace
# an existing extension with the same name in a target environment, preserving
# any custom properties that were applied to it in the target

## Uses certificates and ticketing (for the extension download)
## Requires 4242, 4243 inbound on the source, and inbound 4242 on the target

################
##### Input ####
################

$source_fqdn = "<SOURCE_FQDN>"
$source_virtual_proxy = "/" # single forward slash for empty, preceding and trailing for non-empty, e.g. /default/
$source_user_directory_for_ticket = "<USER_DIR>"
$source_user_id_for_ticket = "<USER_ID>"
$target_fqdn = "<TARGET_FQDN>"
$source_pfx_path = "<ABSOLUTE_PATH>\client.pfx"
$target_pfx_path = "<ABSOLUTE_PATH>\client.pfx"
$source_extension_name = "<EXTENSION_NAME>"
$out_file_path = '<ABSOLUTE_DIR_PATH>\'
$out_file_name = '<FILENAME>.log'
$extension_stage_path = '<ABSOLUTE_DIR_PATH>\'

################
##### Main #####
################

# Handle TLS 1.2 only environments
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12' 

# Set the output paths
$out_file = ($out_file_path + $out_file_name)
$extension_file = ($extension_stage_path + $source_extension_name + '.zip')

# Generate GUID for log ID
$log_id = New-Guid

# if the files already exists, remove them
if (Test-Path $extension_file) {Remove-Item $extension_file}

# Store the certificates to vars for further use (optional)
$source_cert = Get-PfxCertificate $source_pfx_path
$target_cert = Get-PfxCertificate $target_pfx_path

# Import the Qlik Cli module (forcefully to terminate any existing Cli connections)
Import-Module Qlik-Cli -Force

# Connect to the source server
$log = "$log_id`tMessage`tConnecting to '" + $source_fqdn + "'"; Write-Host $log; Add-Content -Path $out_file -Value $log
$source_cert | Connect-Qlik -ComputerName $source_fqdn -UserName INTERNAL\sa_api -TrustAllCerts | Out-Null

# Search for the source extension
$log = "$log_id`tMessage`tSearching for extension '" + $source_extension_name + "'"; Write-Host $log; Add-Content -Path $out_file -Value $log
$source_extension_response = Get-QlikExtension -filter "name eq '$source_extension_name'"

# If the source extension exists, export it
if ($source_extension_response) {
    # Grab the id
    $source_extension_id = $source_extension_response.id
    $log = "$log_id`tMessage`tFound extension '" + $source_extension_name + "' with id '" + $source_extension_id + "'"; Write-Host $log; Add-Content -Path $out_file -Value $log;
    
    # We now need to construct a call to fetch a ticket to download the extension over another API
    # Add in the Xrfkey value to the headers
    $hdrs = @{}
    $hdrs.Add("X-Qlik-Xrfkey","abcdefg123456789")
    $hdrs.Add("X-Qlik-User", "UserDirectory=INTERNAL; UserId=sa_api")

    # Construct the body for the POST request, which will include the user information for the session
    $body = '{"UserDirectory":"' + $source_user_directory_for_ticket + '","UserId":"' + $source_user_id_for_ticket + '"}'

    # Grab a ticket over the QPS
    $log = "$log_id`tMessage`tRequesting a Qlik ticket for the extension download"; Write-Host $log; Add-Content -Path $out_file -Value $log;
    $ticket = Invoke-RestMethod -Uri "https://$($source_fqdn):4243/qps$($source_virtual_proxy)ticket?xrfkey=abcdefg123456789" -Method Post -Body $body -Headers $hdrs -ContentType 'application/json' -Certificate $source_cert
    $ticket = $ticket.Ticket

    if ($ticket) {
        $log = "$log_id`tMessage`tTicket received '" + $ticket + "'"; Write-Host $log; Add-Content -Path $out_file -Value $log;

        # Download the extension using the ticket
        $log = "$log_id`tMessage`tDownloading extension '" + $source_extension_name + "' using ticket '" + $ticket + "'"; Write-Host $log; Add-Content -Path $out_file -Value $log;
        Invoke-QlikDownload -path "https://$($source_fqdn)$($source_virtual_proxy)api/wes/v1/extensions/export/$($source_extension_name)?qlikTicket=$($ticket)" -filename $extension_file
        
        # if the file exists, proceed
        if (Test-Path $extension_file) {
            $file_size = (Get-Item $extension_file).length/1MB
            $log = "$log_id`tMessage`tExtension '" + $source_extension_name + "' stored to disk at '" + $extension_file + "' with file size '" + $file_size + "' MB"; Write-Host $log; Add-Content -Path $out_file -Value $log;
                    
            # Import the Qlik Cli module (forcefully to terminate any existing Cli connections)
            Import-Module Qlik-Cli -Force

            # Connect to the target server
            $log = "$log_id`tMessage`tConnecting to '" + $target_fqdn + "'"; Write-Host $log; Add-Content -Path $out_file -Value $log
            $target_cert | Connect-Qlik -ComputerName $target_fqdn -UserName INTERNAL\sa_api -TrustAllCerts | Out-Null

            # Check to see if an extension with the same name already exists on the target server
            $log = "$log_id`tMessage`tChecking to see if there is already an extension with this name on the target server"; Write-Host $log; Add-Content -Path $out_file -Value $log
            $existing_target_extension = Get-QlikExtension -filter "name eq '$source_extension_name'" -full

            # If a matching extension exists
            if ($existing_target_extension) {
                $existing_target_extension_id = $existing_target_extension.id
                $existing_target_extension_name = $existing_target_extension.name
                $log = "$log_id`tMessage`tMatching extension found with id '" + $existing_target_extension_id + "'"; Write-Host $log; Add-Content -Path $out_file -Value $log

                # Checking for custom properties
                $log = "$log_id`tMessage`tChecking for custom properties"; Write-Host $log; Add-Content -Path $out_file -Value $log

                # Storing any custom properties
                $existing_target_extension_cp = $existing_target_extension.customProperties
                if ($existing_target_extension_cp) {
                    $log = "$log_id`tMessage`tCustom properties exist, stored to variable"; Write-Host $log; Add-Content -Path $out_file -Value $log
                }
                else{
                    $log = "$log_id`tMessage`tNo custom properties exist for this extension"; Write-Host $log; Add-Content -Path $out_file -Value $log
                }

                # Removing target extension
                $log = "$log_id`tMessage`tRemoving existing extension with id '" + $existing_target_extension_id + "'"; Write-Host $log; Add-Content -Path $out_file -Value $log
                Remove-QlikExtension -ename $existing_target_extension_name | Out-Null
                $log = "$log_id`tMessage`tExtension removed"; Write-Host $log; Add-Content -Path $out_file -Value $log
            }
            else {
                # No extension exists with the name
                $log = "$log_id`tMessage`tNo extension with the name '" + $source_extension_name + "' exists on the target server"; Write-Host $log; Add-Content -Path $out_file -Value $log
            }

            # Import new extension
            $log = "$log_id`tMessage`tImporting the source extension"; Write-Host $log; Add-Content -Path $out_file -Value $log
            $imported_extension = Import-QlikExtension -ExtensionPath $extension_file
            $imported_extension_id = $imported_extension.id
            $log = "$log_id`tMessage`tExtension imported with id '" + $imported_extension_id + "'"; Write-Host $log; Add-Content -Path $out_file -Value $log

            # GET the new extension
            $log = "$log_id`tMessage`tGetting the new extension"; Write-Host $log; Add-Content -Path $out_file -Value $log
            $imported_extension = Get-QlikExtension -Id $imported_extension.id -raw

            if ($existing_target_extension_cp) {
                # Apply custom properties
                $log = "$log_id`tMessage`tApplying custom properties"; Write-Host $log; Add-Content -Path $out_file -Value $log

                # Add the custom properties
                $imported_extension.customProperties = $existing_target_extension_cp
                
                # Convert the response to JSON
                $imported_extension = $imported_extension | ConvertTo-Json -depth 10

                # PUT the extension with the new custom props
                Invoke-QlikPut -path /qrs/extension/$imported_extension_id -body $imported_extension | Out-Null

                $log = "$log_id`tMessage`tCustom properties have been applied to extension with id '" + $imported_extension_id + "'"; Write-Host $log; Add-Content -Path $out_file -Value $log
            }

            # Clean up staged zip
            $log = "$log_id`tMessage`tRemoving the staged zip file."; Write-Host $log; Add-Content -Path $out_file -Value $log
            if (Test-Path $extension_file) {Remove-Item $extension_file}

            $log = "$log_id`tMessage`tSuccessfully executed script."; Write-Host $log; Add-Content -Path $out_file -Value $log

        }
        else {
            $log = "$log_id`tMessage`tSomething went wrong while exporting the extension '" + $source_extension_name + "'"; Write-Host $log; Add-Content -Path $out_file -Value $log
        }
    }
    else {
        $log = "$log_id`tMessage`tThere was a problem requesting the ticket"; Write-Host $log; Add-Content -Path $out_file -Value $log;
    }
}
else {
    $log = "$log_id`tMessage`tThe extension '" + $source_extension_name + "' doesn't exist."; Write-Host $log; Add-Content -Path $out_file -Value $log
}