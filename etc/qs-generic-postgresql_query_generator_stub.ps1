

$query = "SELECT * FROM `"Apps`" WHERE (`"Name`"=`'Operations Monitor`')`;"
$query | set-content foo.sql -Encoding Ascii

$Data = Get-Content C:\ProgramData\Qlik\Sense\Host.cfg
$FQDN = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($($Data)))

$elevate1 = "UPDATE `"LocalConfigs`" SET `"HostName`" = '$($FQDN)' WHERE `"HostName`" = (SELECT `"HostName`" FROM `"ServerNodeConfigurations`" WHERE `"IsCentral`"='true')`;"
$elevate2 = "UPDATE `"ServerNodeConfigurations`" SET `"HostName`" = '$($FQDN)' WHERE `"HostName`" = (SELECT `"HostName`" FROM `"ServerNodeConfigurations`" WHERE `"IsCentral`"='true');"
$elevate1 | set-content qs_2018-04-elevate1.sql -Encoding Ascii
$elevate2 | set-content qs_2018-04-elevate2.sql -Encoding Ascii
# C:\"Program Files"\Qlik\Sense\Repository\PostgreSQL\9.6\bin\psql.exe -h localhost -p 4432 -U postgres -d QSR -f "C:\Users\ltu\scripts\foo.sql"