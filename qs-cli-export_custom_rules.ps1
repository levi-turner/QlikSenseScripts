Connect-Qlik
Set-Location /
if (Test-Path C:\Temp) {
     # C:\Temp exists
} else {
	# Creating C:\Temp
    New-Item -Name Temp -ItemType directory
}
Get-QlikRule -filter "type eq 'custom' and category eq 'security'" -full -raw | ConvertTo-Json | Out-File C:\Temp\qlikrules.json