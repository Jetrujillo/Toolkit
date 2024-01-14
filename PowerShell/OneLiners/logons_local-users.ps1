$lun=("({0})" -f ((Get-LocalUser).where({$_.Enabled -eq $true}).Name -join '|'));(Get-WinEvent -LogName 'Security' -FilterXPath "*[System[EventID=4624]]").where({$_.Message -imatch $lun}) | % { Write-Host ("{0} - {1}" -f ($_.Properties.Value | Select-String -Pattern $lun), $_.TimeCreated)}