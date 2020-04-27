# Import Flow

$exportPath = 'C:\tmp'
$virtualProxyPrefix = '' # if the prefixless virtual proxy does not use Windows authentication, define the prefix for the virtual proxy which does Windows auth e.g. /windows


$hdrs = @{}
$hdrs.Add("X-Qlik-Xrfkey","examplexrfkey123")
$hdrs.Add("X-Qlik-User", "UserDirectory=INTERNAL; UserId=sa_api")
$cert = Get-ChildItem -Path "Cert:\CurrentUser\My" | Where {$_.Subject -like '*QlikClient*'}
$Data = Get-Content C:\ProgramData\Qlik\Sense\Host.cfg
$FQDN = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($($Data)))
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12'

Set-Location $exportPath
$extensions = Get-ChildItem -filter *.zip
foreach ($extension in $extensions) {
    $response = $null
    $response = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/extension/upload?xrfkey=examplexrfkey123" -Method Post  -Headers $hdrs -ContentType 'application/vnd.qlik.sense.app' -Certificate $cert -InFile $($extension.name)
    if ($response.Length -eq 0) {
        Write-Warning "$extension.name upload failed"
    } else {
        Write-Host "$extension.name uploaded"
    }
}