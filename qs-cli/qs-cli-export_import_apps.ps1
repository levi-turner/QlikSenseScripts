# This script will export an application from the source environment by name and stream, and
# then import it to a target environment with the same name and stream, publishing and replacing
# over any existing app that exists with the same name in the target stream.

## Uses certificates
## Requires 4242 inbound on the source and target

################
##### Input ####
################

$source_fqdn = "<SOURCE_FQDN>"
$target_fqdn = "<TARGET_FQDN>"
$source_pfx_path = "<ABSOLUTE_PATH>\client.pfx"
$target_pfx_path = "<ABSOLUTE_PATH>\client.pfx"
$source_app_name = "<APP NAME>"
$source_app_stream = "<STREAM NAME>"
$out_file_path = '<ABSOLUTE_DIR_PATH>\'
$out_file_name = '<FILENAME>.log'
$qvf_stage_path = '<ABSOLUTE_DIR_PATH>\'

################
##### Main #####
################

# Handle TLS 1.2 only environments
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12' 

# set the output paths
$out_file = ($out_file_path + $out_file_name)
$qvf_file = ($qvf_stage_path + $source_app_name + '.qvf')

# Generate GUID for log ID
$log_id = New-Guid

# if the files already exists, remove them
if (Test-Path $qvf_file) {Remove-Item $qvf_file}

# Store the certificates to vars for further use (optional)
$source_cert = Get-PfxCertificate $source_pfx_path
$target_cert = Get-PfxCertificate $target_pfx_path

# Import the Qlik Cli module (forcefully to terminate any existing Cli connections)
Import-Module Qlik-Cli -Force

# Connect to the source server
$log = "$log_id`tMessage`tConnecting to '" + $source_fqdn + "'"; Write-Host $log; Add-Content -Path $out_file -Value $log
$source_cert | Connect-Qlik -ComputerName $source_fqdn -UserName INTERNAL\sa_api -TrustAllCerts | Out-Null

# Search for the source app
$log = "$log_id`tMessage`tSearching for app '" + $source_app_name + "'"; Write-Host $log; Add-Content -Path $out_file -Value $log
$source_app_response = Get-QlikApp -filter "name eq '$source_app_name' and stream.name eq '$source_app_stream'"

# If the source app exists, get the stream it is in and then export it
if ($source_app_response) {
    # Grab the id and the stream name of the app
    $source_app_id = $source_app_response.id
    $log = "$log_id`tMessage`tFound app '" + $source_app_name + "' with id '" + $source_app_id + "' in stream '" + $source_app_stream + "' with id '" + $source_app_response.stream.id + "'"; Write-Host $log; Add-Content -Path $out_file -Value $log;

    # Export the app
    Export-QlikApp -id $source_app_id -filename $qvf_File
    if (Test-Path $qvf_file) {
        $file_size = (Get-Item $qvf_file).length/1MB
        $log = "$log_id`tMessage`tApp '" + $source_app_name + "' stored to disk at '" + $qvf_file + "' with file size '" + $file_size + "' MB"; Write-Host $log; Add-Content -Path $out_file -Value $log;
    }
    else {
        $log = "$log_id`tMessage`tSomething went wrong while exporting the app '" + $source_app_name + "'"; Write-Host $log; Add-Content -Path $out_file -Value $log
    }

    # Import the Qlik Cli module (forcefully to terminate any existing Cli connections)
    Import-Module Qlik-Cli -Force

    # Connect to the target server
    $log = "$log_id`tMessage`tConnecting to '" + $target_fqdn + "'"; Write-Host $log; Add-Content -Path $out_file -Value $log
    $target_cert | Connect-Qlik -ComputerName $target_fqdn -UserName INTERNAL\sa_api -TrustAllCerts | Out-Null

    # Check to see if an app with the same name already exists in the target stream
    $log = "$log_id`tMessage`tChecking to see if there is already an app with this name published to this stream"; Write-Host $log; Add-Content -Path $out_file -Value $log
    $existing_target_app = Get-QlikApp -filter "name eq '$source_app_name' and stream.name eq '$source_app_stream'"

    # if a matching app exists, import and publish and replace, else import and publish
    if ($existing_target_app) {
        $existing_target_app_id = $existing_target_app.id
        $log = "$log_id`tMessage`tMatching app found with id '" + $existing_target_app_id + "'"; Write-Host $log; Add-Content -Path $out_file -Value $log

        # Importing the app
        $log = "$log_id`tMessage`tImporting app '" + $source_app_name + "'"; Write-Host $log; Add-Content -Path $out_file -Value $log
        $imported_app = Import-QlikApp -name $source_app_name -file $qvf_file -upload
        $imported_app_id = $imported_app.id

        # Switching the app which is ultimately publishing and replacing
        $log = "$log_id`tMessage`tPublishing and replacing imported app '" + $imported_app.id + "' over existing app '" + $existing_target_app_id + "'"; Write-Host $log; Add-Content -Path $out_file -Value $log
        Switch-QlikApp -Id $imported_app_id -AppId $existing_target_app_id | Out-Null
        $log = "$log_id`tMessage`tApp '" + $source_app_name + "' has been published to '" + $source_app_stream + "'"; Write-Host $log; Add-Content -Path $out_file -Value $log

        # Removing the imported app that was used to publish and replace the existing
        $log = "$log_id`tMessage`tRemoving application that was used to publish '" + $imported_app_id + "'"; Write-Host $log; Add-Content -Path $out_file -Value $log
        Remove-QlikApp -Id $imported_app_id | Out-Null
    }
    else {
        $log = "$log_id`tMessage`tChecking to to see if the stream '" + $source_app_stream + "' exists"; Write-Host $log; Add-Content -Path $out_file -Value $log
        $existing_target_stream = Get-QlikStream -filter "name eq '$source_app_stream'"
        $existing_target_stream

        if ($existing_target_stream) {
            # Import and publish the app to the target stream
            $log = "$log_id`tMessage`tNo matching app found, importing app '" + $source_app_name + "' and publishing it to '" + $source_app_stream + "'"; Write-Host $log; Add-Content -Path $out_file -Value $log
            $imported_app = Import-QlikApp -name $source_app_name -file $qvf_file -upload | Publish-QlikApp -stream $source_app_stream
            $log = "$log_id`tMessage`tApp '" + $source_app_name + "' has been published to '" + $source_app_stream + "'"; Write-Host $log; Add-Content -Path $out_file -Value $log
        }
        else {
            $log = "$log_id`tMessage`tThe stream '" + $source_app_stream + "' doesn't exist"; Write-Host $log; Add-Content -Path $out_file -Value $log
        }
    }

    # Clean up staged qvf
    $log = "$log_id`tMessage`tRemoving the staged qvf file."; Write-Host $log; Add-Content -Path $out_file -Value $log
    if (Test-Path $qvf_file) {Remove-Item $qvf_file}

    $log = "$log_id`tMessage`tSuccessfully executed script."; Write-Host $log; Add-Content -Path $out_file -Value $log

}
else {
    # The source app doesn't exist
    $log = "$log_id`tMessage`tThe app '" + $source_app_name + "' either doesn't exist or it isn't published."; Write-Host $log; Add-Content -Path $out_file -Value $log
}