$hdrs = @{}
$hdrs.Add("X-Qlik-Xrfkey","examplexrfkey123")
$hdrs.Add("X-Qlik-User", "UserDirectory=INTERNAL; UserId=sa_api")
$cert = Get-ChildItem -Path "Cert:\CurrentUser\My" | Where {$_.Subject -like '*QlikClient*'}
$body = '{}'
$Data = Get-Content C:\ProgramData\Qlik\Sense\Host.cfg
$FQDN = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($($Data)))
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12' 
$app = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/app/full?filter=(name eq 'Random Data')&xrfkey=examplexrfkey123" -Method Get -Headers $hdrs -ContentType 'application/json' -Certificate $cert
$exporttoken = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/App/$($app.id)/export/6f9e5622-7306-4b00-9da2-15b132cf7984?xrfkey=examplexrfkey123&skipdata=true" -Method Post -Body $body -Headers $hdrs -ContentType 'application/json' -Certificate $cert
Invoke-RestMethod -Uri "https://$($FQDN):4242$($exporttoken.downloadPath)" -Method Get -Headers $hdrs -ContentType 'application/json' -Certificate $cert |  Set-Content "$($app.name).qvf" -Encoding Ascii