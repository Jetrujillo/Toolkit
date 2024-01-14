function Get-BetterNetTCPConnection {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$false, Position=0)]
        [string]$Pattern = ".*"
    )

    $a = Get-NetTCPConnection
    $connections = [System.Collections.Generic.list[object]]::new()
    foreach ($item in $a){
        $b = Get-Process -Id $($item.OwningProcess) -IncludeUserName -ErrorAction SilentlyContinue
        $withProcess = [PSCustomObject]@{
            LocalAddress = $item.LocalAddress
            LocalPort = $item.LocalPort
            RemoteAddress = $item.RemoteAddress
            RemotePort = $item.RemotePort
            State = $item.State
            AppliedSetting = $item.AppliedSetting
            OwningProcessUser = $b.UserName
            OwningProcessID = $item.OwningProcess
            OwningProcess = $b.Processname
            OwningProcessFile = (Get-Process -Id $($item.OwningProcess) -FileVersion -ErrorAction SilentlyContinue).FileName 
        }
        $connections.Add($withProcess)
    }

    return $connections | Where-Object {$_ -imatch $Pattern}
}

function Get-EvenBetterNetTCPConnection {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$false, Position=0)]
        [string]$Pattern = ".*"
    )

    $a = Get-NetTCPConnection
    $connections = [System.Collections.Generic.list[object]]::new()
    foreach ($item in $a){
        $item_pid = $item.OwningProcess
        $b = Get-Process -Id $($item.OwningProcess) -IncludeUserName -ErrorAction SilentlyContinue
        $c = Get-WmiObject -Query "select * from win32_process where ProcessId=$item_pid"
        $withProcess = [PSCustomObject]@{
            LocalAddress = $item.LocalAddress
            LocalPort = $item.LocalPort
            RemoteAddress = $item.RemoteAddress
            RemotePort = $item.RemotePort
            State = $item.State
            AppliedSetting = $item.AppliedSetting
            OwningProcessUser = $b.UserName
            OwningProcessID = $item.OwningProcess
            OwningProcess = $b.Processname
            OwningProcessFile = $c.ExecutablePath
            Command = $c.CommandLine
        }
        $connections.Add($withProcess)
    }

    return $connections | Where-Object {$_ -imatch $Pattern}
}