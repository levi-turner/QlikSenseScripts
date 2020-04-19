$hdrs = @{}
$hdrs.Add("X-Qlik-Xrfkey","examplexrfkey123")
$hdrs.Add("X-Qlik-User", "UserDirectory=INTERNAL; UserId=sa_api")
$cert = Get-ChildItem -Path "Cert:\CurrentUser\My" | Where {$_.Subject -like '*QlikClient*'}
$Data = Get-Content C:\ProgramData\Qlik\Sense\Host.cfg
$FQDN = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($($Data)))
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12' 
$app = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/app/full?filter=(name eq 'Operations Monitor')&xrfkey=examplexrfkey123" -Method Get -Headers $hdrs -ContentType 'application/json' -Certificate $cert


$hdrs = @{}
$hdrs.Add("X-Qlik-Xrfkey","examplexrfkey123")
$hdrs.Add("X-Qlik-User", "UserDirectory=INTERNAL; UserId=sa_api")
$cert = Get-ChildItem -Path "Cert:\CurrentUser\My" | Where {$_.Subject -like '*QlikClient*'}
$Data = Get-Content C:\ProgramData\Qlik\Sense\Host.cfg
$FQDN = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($($Data)))
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12' 
$stream = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/stream/full?filter=(name eq 'Everyone')&xrfkey=examplexrfkey123" -Method Get -Headers $hdrs -ContentType 'application/json' -Certificate $cert

$moveBody = '{"streamId":"'
$moveBody += $stream.id
$moveBody += '","appName":"'
$moveBody += $app.name
$moveBody += '"}'


Invoke-RestMethod -Uri "https://$($FQDN)/api/hub/v1/apps/$($app.id)/move" -Method Put -Body $moveBody -UseDefaultCredentials