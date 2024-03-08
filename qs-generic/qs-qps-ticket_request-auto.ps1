# Build headers
$hdrs = @{}
$hdrs.Add("X-Qlik-Xrfkey","examplexrfkey123")
$hdrs.Add("X-Qlik-User", "UserDirectory=INTERNAL; UserId=sa_api")
# Get cert to make QPS API call on 4243
$cert = Get-ChildItem -Path "Cert:\CurrentUser\My" | Where {$_.Subject -like '*QlikClient*'}
# Dynamically determine the FQDN for the Qlik site, useful only when executed on a Qlik node
$Data = Get-Content C:\ProgramData\Qlik\Sense\Host.cfg
$FQDN = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($($Data)))
# Body of the user including required attributes (UserDirectory and UserId) as well as optional attributes
$body = '{"UserDirectory": "DEMO", "UserId": "xyz", "Attributes": [{"extendedRole": "exampleRole"}]}'
# Handle for TLS versions
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12' 
# Request ticket
$ticket = Invoke-RestMethod -Uri "https://$($FQDN):4243/qps/ticket?xrfkey=examplexrfkey123" -Method Post -Body $body -Headers $hdrs -ContentType 'application/json' -Certificate $cert
# build URL used to claim ticket
$url = 'https://'
$url += $($FQDN)
$url += '/hub/?qlikTicket='
$url += $($ticket.Ticket)
# Open URL using Chrome Incognito
Set-Location "C:\Program Files (x86)\Google\Chrome\Application\"
.\chrome.exe $url -incognito
