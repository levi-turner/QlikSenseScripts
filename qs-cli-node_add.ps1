#Requires -Modules Qlik-Cli
<#
Run on the Central
#>
# Connect to Qlik Sense
Connect-Qlik
# Add the node
$password = New-QlikNode -hostname qlikserver2.domain.local -name qlikserver2 -nodePurpose 0 -engineEnabled -proxyEnabled
$foo = @{__pwd="$password"}
<#
Using this will allow a silent execution without password prompt
$Username = 'DOMAIN\Administrator'
$Password = 'Password123!'
$pass = ConvertTo-SecureString -AsPlainText $Password -Force
$Cred = New-Object System.Management.Automation.PSCredential -ArgumentList $Username,$pass
Invoke-Command -ComputerName qlikserver2.domain.local -ScriptBlock { Invoke-WebRequest -Uri "http://localhost:4570/certificateSetup" -Method Post -Body $Using:foo } -credential $Cred
#>
Invoke-Command -ComputerName qlikserver2.domain.local -ScriptBlock { Invoke-WebRequest -Uri "http://localhost:4570/certificateSetup" -Method Post -Body $Using:foo } -credential DOMAIN\Administrator
# Filter by the name param from line 7
$nodeid = Get-QlikNode -filter "(name eq 'qlikserver2')"
Invoke-QlikGet -path /qrs/servernoderegistration/start/$($nodeid.id)