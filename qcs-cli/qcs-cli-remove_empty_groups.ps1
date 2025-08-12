qlik context use showcase
$groups = qlik group ls --limit 10000 | ConvertFrom-Json
Write-Host "$($groups.count) groups found"
foreach($group in $groups) {
    $group_users = qlik user ls --filter "assignedGroups.id eq ""$($group.id)""" | ConvertFrom-Json
    IF($($group_users.count) -gt 0) {
            #do nothing
            Write-Host "NOT Removing Group: $($group.name) because group has $($group_users.count) users"
    } ELSE {
        #delete group
        qlik group rm $($group.id)
    }
}
$groups_after = qlik group ls --limit 10000 | ConvertFrom-Json
Write-Host "$($groups.count - $groups_after.count) groups removed"