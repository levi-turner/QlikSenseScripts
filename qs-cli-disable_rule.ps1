Connect-Qlik
function Update-QlikRule {
    [CmdletBinding()]
    param (
      [parameter(Mandatory=$true,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True,Position=0)]
      [string]$id,
      [string]$name,
  
      [ValidateSet("License","Security","Sync")]
      [string]$category,
  
      [string]$rule,
  
      [alias("filter")]
      [string]$resourceFilter,
  
      [ValidateSet("hub","qmc","both")]
      [alias("context")]
      [string]$rulecontext,
  
      [int64]$actions,
      [string]$comment,
      [switch]$disabled
    )
  
    PROCESS {
      switch ($rulecontext)
      {
        both { $context = 0 }
        hub { $context = 1 }
        qmc { $context = 2 }
      }
  
      $systemrule = Get-QlikRule $id -raw
      If( $name ) { $systemrule.name = $name }
      If( $rule ) { $systemrule.rule = $rule }
      If( $resourceFilter ) { $systemrule.resourceFilter = $resourceFilter }
      If( $category ) { $systemrule.category = $category }
      If( $rulecontext ) { $systemrule.rulecontext = $context }
      If( $actions ) { $systemrule.actions = $actions }
      If( $comment ) { $systemrule.comment = $comment }
      If( $psBoundParameters.ContainsKey("disabled") ) { $systemrule.disabled = "true" }
      echo $disabled
  
      $json = $systemrule | ConvertTo-Json -Compress -Depth 10
      return Invoke-QlikPut "/qrs/systemrule/$id" $json
    }
  }
Get-QlikRule -filter "name eq 'foo'" | Update-QlikRule -disabled -Verbose 
