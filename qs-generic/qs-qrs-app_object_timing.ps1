$hdrs = @{}
$hdrs.Add("X-Qlik-Xrfkey","examplexrfkey123")
$hdrs.Add("X-Qlik-User", "UserDirectory=INTERNAL; UserId=sa_api")
$cert = Get-ChildItem -Path "Cert:\CurrentUser\My" | Where {$_.Subject -like '*QlikClient*'}
$Data = Get-Content C:\ProgramData\Qlik\Sense\Host.cfg
$FQDN = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($($Data)))
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12'
$startTime = (Get-Date)
Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/app/object/full?xrfkey=examplexrfkey123" -Method Get -Headers $hdrs -ContentType 'application/json' -Certificate $cert > Out-null
$endTime = (Get-Date)
$ElapsedTime = (($endTime-$startTime).TotalSeconds)
echo $ElapsedTime
