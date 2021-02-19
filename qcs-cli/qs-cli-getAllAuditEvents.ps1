$new_audit_events = qlik audit ls --limit 100 --raw | ConvertFrom-Json;
$all_audit_events = $new_audit_events.data;
 
try { $next_path = [regex]::match($new_audit_events.links.next.href, '(?<=&next=)(?(?!&|$).)*').Value; }
catch { $next_path = $null }
 
WHILE ($next_path) {
    $new_audit_events = qlik audit ls --limit 100 --next $next_path --raw | ConvertFrom-Json;
     
    try { $next_path = [regex]::match($new_audit_events.links.next.href, '(?<=&next=)(?(?!&|$).)*').Value; }
    catch { $next_path = $null }
 
    $all_audit_events += $new_audit_events.data;
}
