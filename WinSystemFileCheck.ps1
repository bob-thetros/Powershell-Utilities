#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Runs 'sfc /scannow' and creates a dated report in C:\scripts\reports.
.DESCRIPTION
    Runs 'sfc /scannow' and creates a dated report in C:\scripts\reports.
    Displays whether repairs were made, then pauses 2 seconds before exiting.
.PARAMETER
 None
.EXAMPLE
.\WinSystemFileCheck.ps1
#>
#Start-Process -FilePath "C:\Windows\System32\sfc.exe" -ArgumentList '/scannow' -Wait -Verb RunAs -WindowStyle Hidden
# --------------------------------------------------------------------
# RunSfcReport.ps1
#
# Runs 'sfc /scannow' and creates a dated report in C:\scripts\reports.
# Displays whether repairs were made, then pauses 2 seconds before exiting.
# --------------------------------------------------------------------

# ------------------------------------------------------------
# Basic constants & output folder
# ------------------------------------------------------------
$LogBase      = "C:\scripts\reports"
$DateStamp    = Get-Date -Format 'yyyyMMdd-HHmmss'
$OutDir     = Join-Path $LogBase "\reports\$($env:COMPUTERNAME)-sfcheck-$DateStamp"

if (-not (Test-Path $OutDir)) {
    New-Item -ItemType Directory -Path $OutDir | Out-Null
}

# ------------------------------------------------------------
# Prepare to run SFC (hidden console)
# ------------------------------------------------------------
$procInfo = New-Object System.Diagnostics.ProcessStartInfo
$procInfo.FileName   = 'sfc.exe'
$procInfo.Arguments  = '/scannow'
$procInfo.RedirectStandardOutput = $true
$procInfo.UseShellExecute      = $false
$procInfo.CreateNoWindow       = $true

# ------------------------------------------------------------
# Run SFC and capture console output
# ------------------------------------------------------------
Write-Host "Running 'sfc /scannow'  please wait this may take 5 minutes or more..."
$proc   = [System.Diagnostics.Process]::Start($procInfo)
$sfcOut = @()

while (-not $proc.HasExited) {
    if ($proc.StandardOutput.Peek() -ge 0) {
        $line = $proc.StandardOutput.ReadLine()
        $sfcOut += $line
    }
    else { Start-Sleep -Milliseconds 200 }   # keep loop busy‑wait minimal
}

# Grab any remaining lines after exit
while ($proc.StandardOutput.Peek() -ge 0) {
    $sfcOut += $proc.StandardOutput.ReadLine()
}
$proc.WaitForExit()

# Save console log
$sfcLogPath = Join-Path $OutDir "SFC_Console_$DateFolder.txt"
Set-Content -Encoding utf8 -Path $sfcLogPath -Value ($sfcOut -join "`n")

# ------------------------------------------------------------
# Grab CBS log snippet (last ~2000 chars)
# ------------------------------------------------------------
$CBSlog   = "$env:SystemRoot\Logs\CBS\CBS.log"
$cbsFull  = Get-Content -Path $CBSlog -Raw
$cbsChunk = if ($cbsFull.Length -gt 2000) { $cbsFull.Substring($cbsFull.Length - 2000) } else { $cbsFull }

$cbsLogPath = Join-Path $OutDir "CBS_Snippet_$DateFolder.txt"
Set-Content -Encoding utf8 -Path $cbsLogPath -Value $cbsChunk

# ------------------------------------------------------------
# Parse CBS for repair actions
# ------------------------------------------------------------
$repairLines = ($cbsChunk -split "`n") | Where-Object {
    $_ -match '(Repair|The system file)'   # simple keyword test
}

$repaired = ($repairLines.Count -gt 0)

# ------------------------------------------------------------
# Display result & pause
# ------------------------------------------------------------
if ($repaired) {
    Write-Host "SFC repaired one or more files." -ForegroundColor Yellow
    Write-Host "See the logs in $OutDir for details."
}
else {
    Write-Host "No corrupt files were found." -ForegroundColor Green
    Write-Host "See the logs in $OutDir for details."
}

Start-Sleep -Seconds 2   # brief pause before script exits

# --------------------------------------------------------------------

# SIG # Begin signature block
# MIIFuwYJKoZIhvcNAQcCoIIFrDCCBagCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUsBD+ZIsBhWUJclOR3wqxeXfo
# MD+gggM8MIIDODCCAiCgAwIBAgIQVc1z35+8BY5JQpb70tzgIDANBgkqhkiG9w0B
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
# BAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUxjVgHNHv3Q/3YlynpyYISyRpeCwwDQYJ
# KoZIhvcNAQEBBQAEggEAMWWxMcxd5SKu8GPxGtTYZnXpeZ1jNw2uFHrBH6Z2NwX0
# sQ6jr7sK/SIvfrjR/DdncS/kjugd3QNcoTWcexMIFdllV6HDwRGTkZCQp/67RDmg
# SOPsdbaMeaW65ahudR71SgvV/xuf140BM3xxkPW30oZiQpTpzFgREMo6QZDxDz8r
# H4pd7QwoIBcrY6AdNzy6Td+c6OJ8QWCrvu5RRlxgzQpnGThDUb8BAxfsMwbmpyqX
# V17O7HsTThZYi+vFhx2px+uDEvrBJg+SCKJgwwmPcUaa2a+seB1HjpaJBbXTOZi1
# A+ruzTAT+ZUFBb1kfq2kkt0xBRzbBHv/4Q15bTbzKw==
# SIG # End signature block
