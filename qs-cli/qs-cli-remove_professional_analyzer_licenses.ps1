#Requires -Modules Qlik-Cli

# Set the inactivity threshold. This is interactive. A non-interactive version can use this appproach:
## $InactivityThreshold = '30' # This is for 30 days
$InactivityThreshold = Read-Host -Prompt 'Input the username date threshold for inactivity (e.g. 90)'

# Get date format for 90 days ago
$date = Get-Date
$date = $date.AddDays(-$InactivityThreshold)
$date = $date.ToString("yyyy/MM/dd")
$time = Get-Date
$time = $time.GetDateTimeFormats()[109]
$inactive = $date + ' ' + $time

# Connect using Qlik-CLI
Connect-Qlik | Out-Null

# Remove Analyzer Access passes over date threshold
Get-QlikAnalyzerAccessType -filter "lastUsed lt '$inactive'" -full  | Remove-QlikAnalyzerAccessType

# Remove Professional Access passes over date threshold
Get-QlikProfessionalAccessType -filter "lastUsed lt '$inactive'" -full  | Remove-QlikProfessionalAccessType