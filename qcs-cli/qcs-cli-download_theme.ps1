qlik context use showcase
$extension = qlik theme ls | ConvertFrom-Json | Where-Object { $_.name -eq "Qlik Sense Rebrand - No Padding" }
qlik raw get v1/themes/$($extension.id)/file > "$($extension.name).zip"