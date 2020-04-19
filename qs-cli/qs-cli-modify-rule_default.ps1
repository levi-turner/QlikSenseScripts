#Requires -Modules Qlik-Cli
$Data = Get-Content C:\ProgramData\Qlik\Sense\Host.cfg
$FQDN = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($($Data)))
$rawoutput=$true
Connect-Qlik -ComputerName $($FQDN) -Username INTERNAL\sa_api | Out-Null
$rule = Get-QlikRule -filter "name eq 'Example Rule'"
$rulefull = Invoke-QlikGet -path /qrs/systemrule/$($rule.id)
$ruleid = $rulefull.id
$rulefull = $rulefull | ForEach-Object {
   $_.Type = 'Default'
   $_
}
$rulejson = $rulefull | ConvertTo-Json
Invoke-QlikPut -path /qrs/systemrule/$ruleid -body $rulejson | Out-Null