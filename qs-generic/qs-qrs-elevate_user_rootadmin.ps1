$hdrs = @{}
$hdrs.Add("X-Qlik-Xrfkey","examplexrfkey123")
# Now log in as INTERNAL account to elevate
$hdrs.Add("X-Qlik-User", "UserDirectory=INTERNAL; UserId=sa_api")
$userfull = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/user/full?filter=(userdirectory eq 'domain' and name eq 'Administrator')&xrfkey=examplexrfkey123" -Method Get -Headers $hdrs -ContentType 'application/json' -Certificate $cert
$adminuserbody = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/user/$($userfull.id)?xrfkey=examplexrfkey123" -Method Get -Headers $hdrs -ContentType 'application/json' -Certificate $cert
$adminuserbody | Add-Member role RootAdmin -Force
$adminuserbodyjson = $adminuserbody | ConvertTo-Json
$body = $adminuserbodyjson
Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/user/$($userfull.id)?xrfkey=examplexrfkey123" -Method Put -Body $body -Headers $hdrs -ContentType 'application/json' -Certificate $cert  | Out-Null