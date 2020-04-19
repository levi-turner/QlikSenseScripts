$hdrs = @{}
$hdrs.Add("X-Qlik-Xrfkey","examplexrfkey123")
$hdrs.Add("X-Qlik-User", "UserDirectory=INTERNAL; UserId=sa_api")
$cert = Get-ChildItem -Path "Cert:\CurrentUser\My" | Where {$_.Subject -like '*QlikClient*'}
$Data = Get-Content C:\ProgramData\Qlik\Sense\Host.cfg
$FQDN = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($($Data)))
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12' 
$odaglinkfull = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/odaglink/full?filter=(name eq 'foobar')&xrfkey=examplexrfkey123" -Method Get -Headers $hdrs -ContentType 'application/json' -Certificate $cert
Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/odaglink/$($odaglinkfull.id)?xrfkey=examplexrfkey123" -Method Delete -Headers $hdrs -ContentType 'application/json' -Certificate $cert
