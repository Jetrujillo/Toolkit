<#
.SYNOPSIS
    Redact network/domain data from files.
.DESCRIPTION
    Select text/log files as an input. Any matches that are an IPv4 address or defined FQDN/Hostname/Domain will be redacted and a new file will generate in the same location with ".red" (redacted) appended as the new file extension. Example - "log0.txt.red".
.NOTES
    Built using PSVersion 5.1.14393.5127
#>

##region - Add any FQDN or hostname here that you want to redact. All matches are case-insensitive.
$redactFQDN = @(
"example-Host-01.test.local",
"ts01.lab.local"
)

$redactHostName = @(
"example-Host-01",
"ts01"
)

$redactDomain = @(
".test.local",
".lab.local"
)
##endregion
##region - Import helper routines. -!-DO NOT EDIT UNLESS DIRECTED TO DO SO-!-

Add-Type -AssemblyName System.Windows.Forms
$ipv4_regex = "(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)"
$redactNamesList = (($redactFQDN -join "|") + "|" + ($redactHostName -join "|") + "|" + ("([a-zA-Z0-9\-]+(?:"+ ($redactDomain -join "|") + "))")).replace(".","\.")

function Get-FileName {  
    [CmdletBinding()]  
    Param (   
        [Parameter(Mandatory = $false)]  
        [string]$WindowTitle = 'Open One or More Files to Scrub',

        [Parameter(Mandatory = $false)]
        [string]$InitialDirectory,  

        [Parameter(Mandatory = $false)]
        [string]$Filter = "All files (*.*)|*.*"
    ) 
    Add-Type -AssemblyName System.Windows.Forms

    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openFileDialog.Title  = $WindowTitle
    $openFileDialog.Filter = $Filter
    $openFileDialog.CheckFileExists = $true
    $openFileDialog.MultiSelect = $true
    if (![string]::IsNullOrWhiteSpace($InitialDirectory)) { $openFileDialog.InitialDirectory = $InitialDirectory }

    if ($openFileDialog.ShowDialog().ToString() -eq 'OK') {
        $selected = @($openFileDialog.Filenames)
    }
    #clean-up
    $openFileDialog.Dispose()

    return $selected
}

function ScrubFile{
    Param(
        [Parameter(Mandatory=$true, Position=0)]
        $file
    )
    $content = Get-Content -Path $file
    Write-Host "Scrubbing at $file" -ForegroundColor Yellow
    $redactedContent = foreach ($line in $content){
        #Write-Host $line
        if (($line -imatch $ipv4_regex) -or ($line -imatch $redactNamesList)){
            Write-Host "Match" -ForegroundColor Green
            $redacted = ($line -replace $ipv4_regex,'[RedactedIP]') -replace $redactNamesList,'[RedactedName]'
            $redacted
            Write-Host $line
            Write-Host ($redacted) -ForegroundColor Cyan
        }
        else{
            $line
        }
    }
    return $redactedContent
}

##endregion
#############################
# Script Logic
#############################
##region - Ask for files, scrub them, then export to same directory

Write-Host "Selecting Files..." -ForegroundColor Magenta
$scrubFiles = Get-FileName
if(($scrubFiles -eq "") -or ($scrubFiles -eq $null)){
    Write-Host "Did not choose a file. Please run again and choose a test file to scrub." -ForegroundColor Red
    Start-Sleep -Seconds 2
    exit
}
try{
    #do stuff here to redaction
    Write-Host "Going to scrub $($scrubFiles -join ';')"
    foreach ($fileName in $scrubFiles){
        Write-Host "Writing new file to $scrubFile.red`n" -ForegroundColor Yellow
        ScrubFile -file $fileName | Out-File -Force "$fileName.red"
    }
}
catch {
    Write-Host "`nSomething broke unintentionally. Actual exception error will display below." -ForegroundColor DarkYellow
    Write-Host "Failed at Line: $($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor Red
    Write-Host $_.Exception -ForegroundColor Red
    Start-Sleep -Seconds 2
    exit
}
<# Placeholder for future exceptions.
catch [System.Net.WebException]{
    Write-Host "`nSomething broke." -ForegroundColor DarkYellow
    Write-Host "Failed at Line: $($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor Red
    Write-Host $_.Exception -ForegroundColor Red
}
#>
Write-Host "`nFinished" -ForegroundColor Magenta
Start-Sleep -Seconds 2
##endregion