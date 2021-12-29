gci -Recurse -Filter *.qvf | foreach {
    $existing = Get-QlikApp -filter "name eq '$($_.Basename)' and stream.name eq '$($_.Directory.Basename)'"
    $new = Import-QlikApp -file $_.Fullname -name $_.Basename -upload -Verbose:$true
    if ($existing.count -eq 0){
      $new | Publish-QlikApp -stream $_.Directory.Basename -Verbose:$true
    } Else {
      $new | Switch-QlikApp -appid $existing.id -Passthru -Verbose:$true | Remove-QlikApp -Verbose:$true
    }
  }