$hdrs = @{}
$hdrs.Add("X-Qlik-Xrfkey","examplexrfkey123")
$hdrs.Add("X-Qlik-User", "UserDirectory=INTERNAL; UserId=sa_api")
$cert = Get-ChildItem -Path "Cert:\CurrentUser\My" | Where {$_.Subject -like '*QlikClient*'}
$Data = Get-Content C:\ProgramData\Qlik\Sense\Host.cfg
$FQDN = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($($Data)))
$body = '{"UserDirectory": "DEMO", "UserId": "xyz", "Attributes": [{"extendedRole": "exampleRole"}]}'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12' 
$ticket = Invoke-RestMethod -Uri "https://$($FQDN):4243/qps/ticket?xrfkey=examplexrfkey123" -Method Post -Body $body -Headers $hdrs -ContentType 'application/json' -Certificate $cert
$url = 'https://'
$url += $($FQDN)
$url += '/hub/?qlikTicket='
$url += $($ticket.Ticket)
Set-Location "C:\Program Files (x86)\Google\Chrome\Application\"
.\chrome.exe $url -incognito