$exportPath = 'C:\tmp'
$virtualProxyPrefix = '' # if the prefixless virtual proxy does not use Windows authentication, define the prefix for the virtual proxy which does Windows auth e.g. /windows

# GET a list of extensions
$hdrs = @{}
$hdrs.Add("X-Qlik-Xrfkey","examplexrfkey123")
$hdrs.Add("X-Qlik-User", "UserDirectory=INTERNAL; UserId=sa_api")
$cert = Get-ChildItem -Path "Cert:\CurrentUser\My" | Where {$_.Subject -like '*QlikClient*'}
$Data = Get-Content C:\ProgramData\Qlik\Sense\Host.cfg
$FQDN = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($($Data)))
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12'
$extensions = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/extension/full?xrfkey=examplexrfkey123" -Method Get -Headers $hdrs -ContentType 'application/json' -Certificate $cert

# Export Extensions. Note _must_ go over the Qlik Proxy Service
Set-Location $exportPath
$counter = 0
foreach ($extension in $extensions)
{
    ++$counter
    Invoke-RestMethod -Uri "https://$($FQDN)$($virtualProxyPrefix)/api/wes/v1/extensions/export/$($extension.name)" -Method Get -UseDefaultCredentials -OutFile "$($extension.name).zip" | Out-Null
    if (!(Test-Path "$($extension.name).zip")){
    Write-Host $extension.name failed to download
    }
    Write-Host "$($counter) of $($extensions.Count) Exported"
}
