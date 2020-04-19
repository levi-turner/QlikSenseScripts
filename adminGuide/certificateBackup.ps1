# Define your backup directory
$backupDir = 'C:\QSR'

# Define your certificate password
$pwd = 'foobar'

# Create backup directory if needed
if (Test-Path $backupDir) {
} else {
    New-Item -ItemType directory -Path $backupDir > $null
}

# Get Root Certificate Thumbprint
$store = Get-Item "cert:\LocalMachine\Root"; 
$store.Open("ReadOnly"); 
$certs = $store.Certificates.Find("FindByExtension", "1.3.6.1.5.5.7.13.3", $false);
$rootThumb = $certs.Thumbprint

# Get Server Certificate Thumbprint
$store = Get-Item "cert:\LocalMachine\My"; 
$store.Open("ReadOnly"); 
$certs = $store.Certificates.Find("FindByExtension", "1.3.6.1.5.5.7.13.3", $false);
$serverThumb = $certs.Thumbprint

# Get Client Certificate Thumbprint
$store = Get-Item "cert:\CurrentUser\My"; 
$store.Open("ReadOnly"); 
$certs = $store.Certificates.Find("FindByExtension", "1.3.6.1.5.5.7.13.3", $false);
$clientThumb = $certs.Thumbprint

# Export the certificates to the backupDir
$null = certutil -f -p $pwd -exportpfx -privatekey Root $rootThumb "$backupDir\$(Get-Date -Format "yyyy-MM-dd")-root.pfx" 
$null = certutil -f -p $pwd -exportpfx -privatekey MY $serverThumb "$backupDir\$(Get-Date -Format "yyyy-MM-dd")-server.pfx" NoRoot
$null = certutil -f -p $pwd -exportpfx -privatekey -user MY $clientThumb "$backupDir\$(Get-Date -Format "yyyy-MM-dd")-client.pfx" NoRoot