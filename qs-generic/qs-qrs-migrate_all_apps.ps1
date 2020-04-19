#--------------------------------------------------------------------------------------------------------------------------------
#
# Script Name: qs-qrs-migrate_all_apps.ps1
# Description: Manually migrate all apps
# Dependency: Run as service account (or other account authorized to make QRS API calls)
# 
#   Version     Date        Author          Change Notes
#   0.1         2019-04-01  Levi Turner     Initial Version 
# 
#--------------------------------------------------------------------------------------------------------------------------------

$hdrs = @{}
$hdrs.Add("X-Qlik-Xrfkey","examplexrfkey123")
$hdrs.Add("X-Qlik-User", "UserDirectory=INTERNAL; UserId=sa_api")
$cert = Get-ChildItem -Path "Cert:\CurrentUser\My" | Where {$_.Subject -like '*QlikClient*'}
$Data = Get-Content C:\ProgramData\Qlik\Sense\Host.cfg
$FQDN = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($($Data)))
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12' 
$unmigratedapps = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/app/full?filter=(AppStatuss.statusValue eq 0 or AppStatuss.statusValue eq 2 or AppStatuss.statusValue eq 3 or AppStatuss.statusValue eq 4)&xrfkey=examplexrfkey123" -Method Get -Headers $hdrs -ContentType 'application/json' -Certificate $cert
$body = ''
$unmigratedapps | ForEach-Object -Process { 
    Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/app/$($_.id)/migrate?xrfkey=examplexrfkey123" -Method PUT -Headers $hdrs -ContentType 'application/json' -Certificate $cert -Body $body

}