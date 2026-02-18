<#  
.SYNOPSIS
 Add all currently running processes to Windows Defender exclusions, skipping those already excluded.  All actions are logged.
.DESCRIPTION
 Add all currently running processes to Windows Defender exclusions, skipping those already excluded.  All actions are logged.
.PARAMETER none
None

.EXAMPLE
C:\> .\DefenderProcessAllExceptions.ps1
#>

## ---------- Configuration ----------
$LogFolder = 'C:\scripts'
$DateStamp = Get-Date -Format 'yyyyMMdd'
$LogFile   = Join-Path $LogFolder "process-defender-$DateStamp.log"

## Ensure the log folder exists
if (-not (Test-Path $LogFolder)) {
    try { New-Item -ItemType Directory -Path $LogFolder -Force | Out-Null }
    catch { Write-Error "Failed to create log directory '$LogFolder'. Exiting."; exit 1 }
}

## ---------- Helper: Log a message ----------
function Write-Log ($Message, [string]$Level = 'INFO') {
    $TimeStamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $Entry     = "$TimeStamp [$Level] $Message"
    Add-Content -Path $LogFile -Value $Entry
}
Write-Log '=== Starting Defender exclusion process ==='

## ---------- Capture Get-MpPreference output ----------
$TempFile = [System.IO.Path]::GetTempFileName()
try {
    Get-MpPreference | Out-File -FilePath $TempFile -Encoding UTF8 -Force
    Write-Log "Captured Defender preferences to temporary file: $TempFile"
}
catch {
    Write-Error "Failed to capture Defender preferences. $_"
    exit 1
}

## ---------- Parse exclusions from the temp file ----------
$existingExclusions = @()
try {
    # Each line that starts with 'ExclusionProcess' looks like:
    #   ExclusionProcess : notepad.exe
    $lines = Get-Content -Path $TempFile | Where-Object { $_.Trim().StartsWith('ExclusionProcess') }
    foreach ($line in $lines) {
        $parts = $line.Split(':', 2)
        if ($parts.Count -eq 2) {
            $procName = $parts[1].Trim()
            if ($procName) { $existingExclusions += $procName }
        }
    }
    Write-Log "Parsed $($existingExclusions.Count) existing exclusions from file."
}
catch {
    Write-Error "Failed to parse exclusion list. $_"
    exit 1
}
finally {
    # Clean up the temporary file
    Remove-Item -Path $TempFile -Force | Out-Null
}

## ---------- Build list of running process names ----------
$processNames = Get-Process |
                Select-Object -ExpandProperty Path |
                Where-Object { $_ } |            # discard processes without a path
                Split-Path -Leaf |
                Sort-Object -Unique

Write-Log "Found $($processNames.Count) distinct running processes."

## ---------- Add only new exclusions ----------
$added   = @()
$skipped = @()
$errors  = @()

foreach ($proc in $processNames) {
    if ($existingExclusions -contains $proc) {
        Write-Log "Skipped: '$proc already excluded." 'SKIP'
        Write-Host "Existing: $($proc)"
        $skipped += $proc
        continue
    }

    try {
        Write-Host "Adding: $($proc)"
        Add-MpPreference -ExclusionProcess $proc -ErrorAction Stop
        Write-Log "Added: '$proc' to Defender exclusions." 'ADDED'
        $added += $proc
    }
    catch [System.Exception] {
        Write-Log "ERROR adding '$proc': $($_.Exception.Message)" 'ERROR'
        $errors += @{ Process = $proc; Error = $_.Exception.Message }
    }
}

## ---------- Summary ----------
Write-Host "=== Summary ==="
Write-Host "Total processes examined : $($processNames.Count)"
Write-Host "Exclusions added         : $($added.Count)"
Write-Host "Already excluded (skipped): $($skipped.Count)"
Write-Log "=== Summary ==="
Write-Log "Total processes examined : $($processNames.Count)"
Write-Log "Exclusions added         : $($added.Count)"
Write-Log "Already excluded (skipped): $($skipped.Count)"
if ($errors) { Write-Log "Errors encountered       : $($errors.Count)" }

# Detailed error list
foreach ($e in $errors) {
    Write-Log "Process: $($e.Process) Error: $($e.Error)" 'ERROR'
}

Write-Log '=== End of process ===' -Level 'INFO'

# SIG # Begin signature block
# MIIFuwYJKoZIhvcNAQcCoIIFrDCCBagCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUlnBm+PQTJiP/LjDCpLHg21eC
# WWigggM8MIIDODCCAiCgAwIBAgIQVc1z35+8BY5JQpb70tzgIDANBgkqhkiG9w0B
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
# BAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUunA1NCf3iwl6YfCEvHhmxNngfYQwDQYJ
# KoZIhvcNAQEBBQAEggEAL3BHiOOa3clT+VuuEzGizK+0bRtMltfk+gXFS0BFTS67
# /shkA574hhMS59K5bCUaP9LLgx4jWN+st2VL0JeTaYRu3PIpwy4oHvvrilBHA43H
# hh8jHFYimEYPL3rf/fymO/IeRAay/EbKE8+MwWrovIUDENcrgV1yKcNMBjmJiEIP
# q6s7Fx7tdzrs1WNxOu0CkaXPslFMPPIKo8tsKb2KRct31dZh0ISvVxj5431s4Fp/
# GV/duW3/kqVSbPj7QAlfjt0dy82yTNpZ+3pzMbAfJLEcyIkhI5Nlh7KAznZ71jWq
# LUQqT5sGLAdh3dTl+Xbi9202Z4bk7a7dtnqIiJ45JQ==
# SIG # End signature block
