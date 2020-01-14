#Requires -Modules Qlik-Cli
Connect-Qlik
function New-QlikAnalyzerLicenseRule {
[CmdletBinding()]
param (
[parameter(ValueFromPipeline=$true)]
[PSObject]$object,
[string]$name,
[string]$rule,
[string]$comment,
[switch]$disabled
)
PROCESS {
If( $object ) {
$json = $object | ConvertTo-Json -Compress -Depth 5
} else {
$UserAccessGroup = @{ name = $name ; } | ConvertTo-Json -Compress -Depth 10
$licenseId = Invoke-QlikPost "/qrs/License/UserAccessGroup" -body $UserAccessGroup
$json = (@{
category = "License";
type = "Custom";
rule = $rule;
name = $name;
resourceFilter = "License.UserAccessGroup_" + $licenseId.id;
actions = '1';
comment = $comment;
disabled = $disabled.IsPresent;
ruleContext = "QlikSenseOnly";
tags = @();
schemaPath = "SystemRule"
} | ConvertTo-Json -Compress)
}
return Invoke-QlikPost "/qrs/systemrule" $json
}
}
New-UserAccessRule -name 'foo' -rule '((user.name  = "exampleuser"))'