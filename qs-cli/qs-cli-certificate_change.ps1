# Configurable Params:
$certFilePath = 'C:\Temp\wildcard-qlik-poc-nopass.pfx'
# $FQDN = 'myServer.company.com'
$nodeName = 'Central'

# Build the FQDN for the Sense site programmatically.
$Data = Get-Content C:\ProgramData\Qlik\Sense\Host.cfg
$FQDN = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($($Data)))

# Grab the client certificate to connect via an internal account.
$Certificate = Get-PfxCertificate .\client.pfx
Connect-Qlik -ComputerName https://$($FQDN):4242 -Username INTERNAL\sa_api -Certificate $Certificate

# Import the certificate to the OS
$newCert = Import-PfxCertificate -FilePath $certFilePath -CertStoreLocation Cert:\LocalMachine\My

# Get the body of the target node's proxy
$proxyBody = Get-QlikProxy -filter "serverNodeConfiguration.name eq '$($nodeName)'" -full -raw
# Add the new thumbprint to the proxy's body
$proxyBody.Settings | Add-Member sslBrowserCertificateThumbprint $newCert.Thumbprint -Force
$proxyBodyJSON = $proxyBody | ConvertTo-Json -Depth 10
# Inject the new body with the new certificate
Invoke-QlikPut -path "https://$($FQDN):4242/qrs/proxyservice/$($proxyBody.id)" -body $proxyBodyJSON
