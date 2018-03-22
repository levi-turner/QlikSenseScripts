#--------------------------------------------------------------------------------------------------------------------------------
#
# Script Name: qlik_sense_qrs_generic-GET.ps1
# Description: Example of how to make a GET RESTful QRS API call without dependencies
# Dependency: None
# 
#   Version     Date        Author          Change Notes
#   0.1         2018-03-10  Levi Turner     Initial Version 
#                                           (Adapted heavily from others e.g. Damien Villaret, Youness Ghanim)
#   0.2         2018-03-15  Levi Turner     Added TLS 1.2 only support
# 
#--------------------------------------------------------------------------------------------------------------------------------

# Dummy value for the headers
$hdrs = @{}
# Add in the Xrfkey value to the headers
# https://help.qlik.com/en-US/sense-developer/February2018/Subsystems/RepositoryServiceAPI/Content/RepositoryServiceAPI/RepositoryServiceAPI-Connect-API-Using-Xrfkey-Headers.htm
$hdrs.Add("X-Qlik-Xrfkey","examplexrfkey123")
# Add in the User account to the headers
<# 
Any account with sufficient permissions work
If using INTERNAL accounts, then sa_api is preferred
for tracking or auditing purposes.
Reference: https://help.qlik.com/en-US/sense-developer/February2018/Subsystems/RepositoryServiceAPI/Content/RepositoryServiceAPI/RepositoryServiceAPI-Injected-Request-Headers-X-Qlik-User.htm
#>
$hdrs.Add("X-Qlik-User", "UserDirectory=INTERNAL; UserId=sa_api")
# Grab the Client certificate to trust the QRS request
$cert = Get-ChildItem -Path "Cert:\CurrentUser\My" | Where {$_.Subject -like '*QlikClient*'}
# Construct the FQDN
# Use case is being run on the Qlik Sense Server
$myFQDN=(Get-WmiObject win32_computersystem).DNSHostName+"."+(Get-WmiObject win32_computersystem).Domain
$myFQDN = $myFQDN.ToLower()
# Handle TLS 1.2 only environments
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12' 
Invoke-RestMethod -Uri "https://$($myFQDN):4242/qrs/about?xrfkey=12345678qwertyui" -Method Get -Headers $hdrs -ContentType 'application/json' -Certificate $cert
