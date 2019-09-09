$hdrs = @{}
$hdrs.Add("X-Qlik-Xrfkey","examplexrfkey123")
$hdrs.Add("X-Qlik-User", "UserDirectory=INTERNAL; UserId=sa_api")
$cert = Get-ChildItem -Path "Cert:\CurrentUser\My" | Where {$_.Subject -like '*QlikClient*'}
$Data = Get-Content C:\ProgramData\Qlik\Sense\Host.cfg
$FQDN = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($($Data)))
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12' 
# Get the fileextensionwhitelist/full response for the default and specified library type
$fileextensionwhitelistfull = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/fileextensionwhitelist/full?filter=isDefault eq true and libraryType eq 1&xrfkey=examplexrfkey123" -Method Get -Headers $hdrs -ContentType 'application/json' -Certificate $cert
# Get full json for the above
$fileextensionwhitelistid = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/fileextensionwhitelist/$($fileextensionwhitelistfull.id)?xrfkey=examplexrfkey123" -Method Get -Headers $hdrs -ContentType 'application/json' -Certificate $cert
# Get fileextension json for the xlsb type
$fileextensionxlsb = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/fileextension/full?filter=name eq 'xlsb'&xrfkey=examplexrfkey123" -Method Get -Headers $hdrs -ContentType 'application/json' -Certificate $cert
# Prune out the fileextension ID
$fileextensionxlsbid = $fileextensionxlsb.id
# Prune out the fileextension name
$fileextensionxlsbname = $fileextensionxlsb.name
# add the fileextension ID and fileextension name to the array of accepted fileExtensions for the fileextensionwhitelist
$fileextensionwhitelistid.fileExtensions += New-object  PSObject -Property([ordered]@{id = $fileextensionxlsbid; name= $fileextensionxlsbname})
# Convert that fileextensionwhitelist to JSON
$fileextensionwhitelistjson = $fileextensionwhitelistid | ConvertTo-Json
$body = $fileextensionwhitelistjson
# Put that adjusted fileextensionwhitelist JSON back into Qlik Sense
Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/fileextensionwhitelist/$($fileextensionwhitelistfull.id)?xrfkey=examplexrfkey123" -Method Put -Body $body -Headers $hdrs -ContentType 'application/json' -Certificate $cert
