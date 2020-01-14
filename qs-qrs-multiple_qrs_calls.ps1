#Requires -Modules PoshRSJob
Invoke-Command -ScriptBlock {
    # Execute 34 iterations of the jmeter test plan for usertype2 (Static Selections)
    1..34 | ForEach-Object {
        Start-RSJob -ScriptBlock {
            Start-Sleep -Seconds 10
            Set-Location C:\Temp\lots_of_qrss; 
            $hdrs = @{}
            $hdrs.Add("X-Qlik-Xrfkey","examplexrfkey123")
            $hdrs.Add("X-Qlik-User", "UserDirectory=INTERNAL; UserId=sa_api")
            $cert = Get-ChildItem -Path "Cert:\CurrentUser\My" | Where {$_.Subject -like '*QlikClient*'}
            $Data = Get-Content C:\ProgramData\Qlik\Sense\Host.cfg
            $FQDN = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($($Data)))
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12' 
            Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/about?xrfkey=examplexrfkey123" -Method Get -Headers $hdrs -ContentType 'application/json' -Certificate $cert > about_$($_).log
        } > Out-Null
        Write-Host 'Executing' (Get-RSJob).count 'Jobs'
    } 
}
