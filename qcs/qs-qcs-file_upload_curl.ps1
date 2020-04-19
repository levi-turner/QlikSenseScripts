# Define your tenant URL
$tenant = Get-Content -Path ..\secrets\qcs-tenant.txt

# Define your API key
$apikey = Get-Content -Path ..\secrets\qcs-api_key.txt

Set-Location C:\Apps\curl-7.68.0-win64\bin
curl.exe -k -s X POST --header "Authorization: Bearer $($apikey)" --header "content-type: multipart/form-data" -F data=@"C:\Data\csv\CSV.csv"  https://$($tenant)/api/v1/qix-datafiles?name=CSV.csv -v