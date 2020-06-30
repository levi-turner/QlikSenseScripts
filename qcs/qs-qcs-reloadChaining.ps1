# Define your tenant URL
$tenant = Get-Content -Path ..\secrets\qcs-tenant.txt
# Define your API key
$apikey = Get-Content -Path ..\secrets\qcs-api_key.txt

# Define Apps
$apps = @(
    '7b83c32e-e811-40ae-85f4-773a6c60b136',
    '77ae4b9e-5576-4259-a719-7bfae8472969'
)

# Define schedule

$hourOfDay = '17' # Target hour 0-24 format
$minuteOfHour = '36' # Target Minute 0-59 format

# If it's the current target hour and minute then proceed with reload process
if (((Get-Date).Hour -eq $hourOfDay) -and ((Get-Date).Minute -eq $minuteOfHour)) {
    $apps | ForEach-Object ($_) {
        $hdrs = @{}
        
        # Add in the API key to the headers from the qcs-api_key.txt file
        $hdrs.Add("Authorization","Bearer $($apikey)")

        # Write appId into the Body for reload request
        $bodyLines = '{"appId":"'
        $bodyLines += $_ 
        $bodyLines += '"}'

        # Get the App Information
        $app = Invoke-RestMethod -Uri "https://$($tenant)/api/v1/apps/$($_)" -Method Get -Headers $hdrs

        # Send the reloads request to QCS
        $request = Invoke-RestMethod -Uri "https://$($tenant)/api/v1/reloads" -Body $bodyLines -Method Post -Headers $hdrs

        Write-Host "Beginning reload of $($app.attributes.name)"

        # If the request was created then poll execution for completion
        if($request.status -eq 'CREATED') {
            # Signal reload request success
            Write-Host "Reload Request created for $($app.attributes.name)"
            # Poll every 10 seconds to see if the reload has completed.
            # Valid status values are CREATED, QUEUED, RELOADING, SUCCEEDED, FAILED
            do {
                $reloadStatus = Invoke-RestMethod -Uri "https://$($tenant)/api/v1/reloads/$($request.id)" -Method Get -Headers $
                Start-Sleep -Seconds 10
            } until ($reloadStatus.status -eq 'SUCCEEDED' -or $reloadStatus.status -eq 'FAILED')
            # Log on success
            Write-Host "Reload of $($app.attributes.name) finished with status $($reloadStatus.status)"
        } else {
            Write-Host "Reload Request Failed for $($app.attributes.name)"
        }
    }
} else {
    Write-Host "Not Target Time"
}
