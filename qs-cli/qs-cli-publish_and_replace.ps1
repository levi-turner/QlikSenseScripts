#Requires -Modules Qlik-Cli
Connect-Qlik | Out-Null
$new = Get-QlikApp -filter "name eq 'Operations Monitor(1)'"
$old = Get-QlikApp -filter "name eq 'Operations Monitor'"
Invoke-QlikPut -path /qrs/app/$($new.id)/replace?app=$($old.id) | Out-Null