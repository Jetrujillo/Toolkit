# Example command to generate SSH-Keys:
# -b = bytes | -t = crypto algorithm | -N = pass phrase for auth | -C = Comment for SSH key-pair | -f = key-pair output path and name
# ssh-keygen -b 2048 -t rsa -N "Sup3r-S3cur3!-St00F" -C "This is a comment - jtrujillo@server" -f ./brand-new-key

#$keyConvertFolder = "C:\Program Files\PuTTY\keys\_Convert"
$keyConvertFolder = $PSScriptRoot

$winSCP = [PSCUSTOMOBJECT]@{
    defaultFolderPath = "C:\Program Files (x86)\WinSCP\"
    regFolderPath = (Get-ItemProperty "HKLM:SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\winscp3_is1").InstallLocation
    foundPath = ""
    scpEXE = "WinSCP.exe"
    scpCOM = "WinSCP.com"
}

function CheckWinSCP{
    if (!(Test-Path -LiteralPath $winSCP.defaultFolderPath -PathType Container)){
        if (Test-Path -LiteralPath $winSCP.regFolderPath -PathType Container){
            Write-Host "`nFound WinSCP via reg-key." -ForegroundColor Cyan
            $winSCP.foundPath = $winSCP.regFolderPath
        }
        else{
            Write-Host "`nCan't find the path for WinSCP. Is it installed?" -ForegroundColor Red
            exit 1
        }
    }
    else{
        Write-Host "Found WinSCP at default folder path." -ForegroundColor Cyan
        $winSCP.foundPath = $winSCP.defaultFolderPath
    }
    Write-Host $winSCP.foundPath -ForegroundColor Cyan

    $scpEXECheck = (Test-Path (Join-Path -Path $winSCP.foundPath -ChildPath $winSCP.scpEXE))
    $scpCOMCheck = (Test-Path (Join-Path -Path $winSCP.foundPath -ChildPath $winSCP.scpCOM))

    if (!($scpEXECheck) -or !($scpCOMCheck)){
        Write-Host "`nEXE or COM missing, please see below." -ForegroundColor Red
        $scpCheck = "WinSCP.exe - Exists_{0}`nWinSCP.com - Exists_{1}" -f $scpEXECheck, $scpCOMCheck
        Write-Host "$scpCheck" -ForegroundColor Yellow
        exit 1
    }
    return
}

function CheckIfPrivKey{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$filePath
    )
    #Write-Host "Checking $filePath" -ForegroundColor Yellow
    $privKeyCheck = [PSCUSTOMOBJECT]@{
        file = Split-Path $filePath -Leaf
        folder = Split-Path $filePath -Parent
        fullPath = $filePath
        lineCheck = (Get-Content -Path $filePath -First 1) -imatch "PRIVATE KEY"
    }

    return $privKeyCheck
}

function ConvertPrivKeysPPK{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$winSCPCOMPath,
        [Parameter(Mandatory)]
        [object]$keyFileList
    )
    Write-Host "`nConverting keys..." -ForegroundColor Cyan
    foreach ($privKey in $keyFileList){
        if ($privKey.lineCheck){
            $oldPrivKey = $privKey.fullPath
            $newPrivKey = $oldPrivKey + ".ppk"
            $privKeyPrint = "`nOld - {0}`nNew - {1}" -f $oldPrivKey, $newPrivKey
            Write-Host $privKeyPrint
            #General Command is: winscp.com /keygen mykey.pem /output=mykey.ppk /comment="Converted from OpenSSH format" /changepassphrase
            $convertKeyParams = ("/keygen|`"{0}`"|/output=`"{1}`"" -f $oldPrivKey, $newPrivKey).split("|")
            &"$winSCPCOM" $convertKeyParams
        }
    }
}

## Execution
CheckWinSCP

# Convert Keys?
$winSCPCOM = (Join-Path -Path $winSCP.foundPath -ChildPath $winSCP.scpCOM)
$keyFiles = [System.Collections.Generic.list[object]]::new()
((gci -LiteralPath $keyConvertFolder).FullName) | % {$keyFiles.Add((CheckIfPrivKey -filePath $_))}
ConvertPrivKeysPPK -winSCPCOMPath $winSCPCOM -keyFileList $keyFiles