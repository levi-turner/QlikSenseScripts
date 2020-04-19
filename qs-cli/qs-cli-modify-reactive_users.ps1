#Requires -Modules Qlik-Cli
Connect-Qlik | Out-Null
$Users = ''
$Users = Get-QlikUser  -filter "name eq 'foo1' or name eq 'foo2'" -full -raw
foreach ($element in $Users)
{
   $element
   $element.removedExternally = $false
   $element.inactive = $false
   $UserId = $element.id
   $json = $element | ConvertTo-Json -Compress -Depth 10
   Invoke-QlikPut -path /qrs/user/$UserId -body $json | Out-Null

}