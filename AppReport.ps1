<#
.SYNOPSIS
Lists installed applications and saves the list to a CSV file. Then compares the list to a reference list.
.DESCRIPTION
Compare the existing Apps to the reference list.
.PARAMETER FolderPath
The path to the folder containing the PowerShell scripts.
.EXAMPLE
C:\> .\AppReport.ps1 ref.csv
#>

$BasePath          = 'C:\scripts'  # Adjust as needed
$ArchiveRoot       = Join-Path $BasePath 'Reports'
$ReportFile        = "CompareReport-{0:MM-dd-yyyy}.txt" -f (Get-Date)

# Current state file paths
$appList      = Join-Path $BasePath 'app-list.csv'

# Baseline Path (Important: Set this to the folder containing your baseline files)
$BaselinePath = Join-Path $ArchiveRoot "baseline" # Example - change as needed!
function Ensure-ArchiveFolder {
    param([string]$folder)
    if (-not (Test-Path $folder)) { New-Item -ItemType Directory -Path $folder | Out-Null }
}

function Archive-File {
    param(
        [string]$src,
        [string]$dest
    )
    Write-Host "Archiving $src to $dest"
    if (Test-Path $src) {
        Move-Item -Path $src -Destination $dest -Force | Out-Null
    }
}

function Compare-AndReport {
    param(
         [string]$leftContent,
         [string]$rightContent,
         [string]$header
     )
    $diff = Compare-Object $leftContent.Split("`n") $rightContent.Split("`n") -PassThru | Where-Object { 
        $_.SideIndicator -eq '=>' -or $_.SideIndicator -eq '<=' 
    }
    
    Add-Content -Path $ReportFullPath -Value "====== $header ======"
    $diff | Out-String -Stream | ForEach-Object {$_ -replace "`r",""} | Out-File -FilePath $ReportFullPath -Append
    Write-Host  "$header comparison appended to report."
}

function Export-AppList {
    Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* |
        Select-Object DisplayName,DisplayVersion,Publisher,InstallDate |
        Sort-Object DisplayName |
        Export-Csv -Path $appList -NoTypeInformation
    Write-Host "Application list exported to $appList"
}
function Read-NumericChoice {
    [CmdletBinding()]
    param(
        [string]$Prompt = 'Select an archive number (or 0 to exit): '
    )

    # Declare the variable now – defaulting to 0 so TryParse can write into it
    [int]$choice = 0

    Write-Host -NoNewline $Prompt
    $rawInput = Read-Host

    if (-not [int]::TryParse($rawInput, [ref]$choice)) {
        Write-Host 'That is not a valid number. Aborting.'
        exit 1
    }

    if ($choice -eq 0) {
        Write-Host 'User chose to exit. Exiting script.'
        exit 1
    }
    return $choice
}

#endregion ---- Main Flow -------------------------------------------------
if (-not (Test-Path $BaselinePath)) {
    Ensure-ArchiveFolder -folder $BaselinePath
    Export-AppList
    Archive-File -src $appList    -dest (Join-Path $BaselinePath 'app-list.csv')
    Write-Host "Baseline Created."
    Write-Host $appList
    exit 0
}
# 1. Create archive root if it doesn't exist
Ensure-ArchiveFolder -folder $ArchiveRoot

Ensure-ArchiveFolder -folder $BaselinePath
# 2. Build a dated sub‑folder inside the archive
$DateStamp   = Get-Date -Format 'yyyyMMdd'
$CurrentArch = Join-Path $ArchiveRoot $DateStamp
Ensure-ArchiveFolder -folder $CurrentArch

# 3. Archive any existing current files
Archive-File -src $appList    -dest (Join-Path $CurrentArch 'app-list.csv')
# 4. Capture current state
Export-AppList
# 5. If this is the first run (no previous archive), exit after baseline creation
if (-not (Test-Path -PathType Container -LiteralPath $ArchiveRoot)) {
    Write-Host "Baseline created in $CurrentArch. Update OneNote accordingly." -ForegroundColor Green
    Start-Sleep -Milliseconds 2000
    exit 0
}

# -------------------------------------------------------------
# 6. Prompt user to choose an archive folder for comparison
# -------------------------------------------------------------
$archives = Get-ChildItem -Path $ArchiveRoot -Directory | Sort-Object Name

if ($archives.Count -eq 0) {
    Write-Host "No archive folders found nothing to compare."
    exit 1   # <-- This closing brace was missing in the original script
}

Write-Host "Available baseline archives:" -ForegroundColor Cyan
for ($i = 0; $i -lt $archives.Count; $i++) {
    Write-Host ("{0}. {1}" -f ($i + 1), $archives[$i].Name)
}

$choice = Read-NumericChoice

if ($choice -eq 0) {
    Write-Host "Operation cancelled."
    exit
}

$selectedArchive = $archives[$choice - 1]
Write-Host "You selected: $($selectedArchive.Name)" -ForegroundColor Green

# 7. Build report file path
$ReportFullPath = Join-Path $BasePath $ReportFile
# Check if file exists
if (Test-Path $ReportFullPath) {
    # Clear content of file
    Clear-Content -Path $ReportFullPath
} else {
    Write-Output "File does not exist."
}

Add-Content -Path $ReportFullPath -Value ("Comparison Report {0}" -f (Get-Date))

$BaselinePath = Join-Path $ArchiveRoot $selectedArchive.Name

# 8. Perform comparisons and append to the report
Compare-AndReport `
    -leftContent   (Get-Content -Raw $appList) `
    -rightContent  (Get-Content -Raw (Join-Path $BaselinePath 'app-list.csv')) `
    -header        'Installed Applications'
    
Add-Content -Path $ReportFullPath `
            -Value "`nSystem Information report is located at: $SysInfoArchived`n"
# 9. Open the report for review if desired
$review = Read-Host "Open the report now? (y/n)"
if ($review -eq 'y') { Start-Process notepad++ $ReportFullPath }

Write-Host "Report written to: $($ReportFullPath)" 

Start-Sleep -Milliseconds 2000

# SIG # Begin signature block
# MIIFuwYJKoZIhvcNAQcCoIIFrDCCBagCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU9wMDPfWDcPYpobLAr33kgYlC
# XaOgggM8MIIDODCCAiCgAwIBAgIQVc1z35+8BY5JQpb70tzgIDANBgkqhkiG9w0B
# AQsFADA0MTIwMAYDVQQDDClUSEVUUk9TIExvY2FsIEF1dGhlbnRpY29kZSBTY3Jp
# cHQgU2lnbmluZzAeFw0yNTExMjQwMTM1MDFaFw0yNjExMjQwMTU1MDFaMDQxMjAw
# BgNVBAMMKVRIRVRST1MgTG9jYWwgQXV0aGVudGljb2RlIFNjcmlwdCBTaWduaW5n
# MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA4+5oHdIg5QYhor6AtpWN
# Z2Pb5KAdsP/aBI0xo+e3vhpjhECdYRpJqDj5Nab1ZnDmhYtdHuZyg8urGgzeUNFd
# 732a4RTN0ixu84uhPL4wri+dsX2ouywhA8+kZM2YkGOOxDmaPI8B95sr1gdBTShz
# nuw4mAR+vxTcW39vylieu2Il5dr5+0derzJoEvc5bZgV5Mx550T6BnCnt4W4BEj+
# wFQo7wJwBgTELnxR1MnnSXx9YDcRqqJFn5nUxTVbX57o2YFwoLiX95Y9h2WqwSPj
# EixoUxUtQaPAy6oeMV1aO30M1CP1DqWFlUxTL4s4cCGbdVGaw+KhaiRSfgYJsujt
# jQIDAQABo0YwRDAOBgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMw
# HQYDVR0OBBYEFAdqumITkAbTgAfxq0K4xoKDQpuOMA0GCSqGSIb3DQEBCwUAA4IB
# AQBUWh/hxqMO7fOMO5/IQ762shJzPZHh0CrKGOHDDWo8gjzcKg3355lwv6/XmJV8
# G7cxzQ/m2Jhket2B1S232oZusfgv0JB4pao0rcYnRDif6A3dbMiQWs+O9HYgJz+B
# L02acn3+xROeLnogosBFNWdsFdRzTT+tswMgrO8ctG/bbCZqHAsbZ89Px/1W8agE
# mr0hDMhI5KusjuNwY++ryh1jAbdimPgG35PGBbxpAaVnrinNbtlue2ZEEif56eOE
# YikIv+D32ybQlChnKyK3eQ8Xc0te2RDtOo1ODcTe4HXs5X5Fjd54yqXDdlC7bj5f
# nWErvpkz5seyiZDA25EnLiwlMYIB6TCCAeUCAQEwSDA0MTIwMAYDVQQDDClUSEVU
# Uk9TIExvY2FsIEF1dGhlbnRpY29kZSBTY3JpcHQgU2lnbmluZwIQVc1z35+8BY5J
# Qpb70tzgIDAJBgUrDgMCGgUAoHgwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZ
# BgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYB
# BAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQU37oH8cAWd4HAdYdWQYXB6zsTX5EwDQYJ
# KoZIhvcNAQEBBQAEggEAfARdpRAr/W1IBH8rOq4yJZiF2JsMiFj41qYEXva6ziwu
# 8swvzIVNLJNx/4iIhO0LQAHEkr6K/SY4w52ZR1rEH+np70DjQPxW0yN9mTajMnPX
# vzg+XUW8dCXYBI5LRBvKmxlx3bSO/KgMi9jQnDgIaweEVWljW9TX4V5HuSDd3tQh
# FbpKhbkLTB5/KtJSP0eak+N88VVo4ibrPdWnaa7hwEv309/wbPeFbPbkewUSwXk0
# H1TEpdIL5PkaQWtFa9NNFlTPHxczoD46C+3BJSyJar1gjFoV9HzzivTC2rVjPRTZ
# SgQq8v6TYWOs4b+F0RUze0EdZ5H7kBMXrH/jIdZtSA==
# SIG # End signature block
