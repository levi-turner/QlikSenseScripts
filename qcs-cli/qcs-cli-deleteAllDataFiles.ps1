$files = qlik raw get v1/qix-datafiles | ConvertFrom-Json

while ($($files.Length) -gt 1) {
    foreach ($file in $files) {
        Write-Host "Deleting $($file.name)"
        qlik raw delete v1/qix-datafiles/$($file.id) | Out-Null
    }
    $files = qlik raw get v1/qix-datafiles | ConvertFrom-Json
    Write-Host 'Next page'
}
