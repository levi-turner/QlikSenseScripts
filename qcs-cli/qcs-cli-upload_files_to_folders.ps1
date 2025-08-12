$file_path = 'C:\etc\data\CSV.csv'
$space_name = "Sandbox - Folders"
$space_id = (qlik space ls --name $space_name | ConvertFrom-Json).id
$connection_id = (qlik data-file connection ls --spaceId $space_id | ConvertFrom-Json).id
# create a file in the root of the directory
qlik data-file create --name "csv.csv" --connectionId $connection_id --file $file_path
# create a file in a directory
qlik data-file create --name "some/folder/csv.csv" --connectionId $connection_id --file $file_path