<#
.SYNOPSIS
Set long date format in Windows registry
.DESCRIPTION
Set the long date format in Windows registry to exclude the weekday.
.PARAMETER None
none
.EXAMPLE
C:\> .\SetLongDate.ps1
#>
# ────────────────────────────────────────────────────────
# 1. Define the desired long‑date value (no weekday)
# ────────────────────────────────────────────────────────
$desiredLongDate = 'MMMM d, yyyy'

# ────────────────────────────────────────────────────────
# 2. Helper function – set a registry string value,
#    creating the key if it does not exist.
# ────────────────────────────────────────────────────────
function Set-RegistryStringValue {
    param(
        [Parameter(Mandatory)]
        [string]$Hive,           # e.g. 'HKCU', 'HKLM', or full path like 'HKEY_USERS\S-1-5-19'
        [Parameter(Mandatory)]
        [string]$SubKeyPath,     # e.g. '\Control Panel\International'
        [Parameter(Mandatory)]
        [string]$ValueName,
        [Parameter(Mandatory)]
        [string]$ValueData
    )

    $fullPath = Join-Path -Path $Hive -ChildPath $SubKeyPath

    # Ensure the key exists – Create it if missing
    if (-not (Test-Path $fullPath)) {
        New-Item -Path $fullPath -Force | Out-Null
    }

    Set-ItemProperty -Path $fullPath -Name $ValueName -Value $ValueData -Type String
}

# ────────────────────────────────────────────────────────
# 3. Apply the value to all four locations
# ────────────────────────────────────────────────────────

# a) Current user – HKCU
Set-RegistryStringValue `
    -Hive 'HKCU' `
    -SubKeyPath '\Control Panel\International' `
    -ValueName 'sLongDate' `
    -ValueData $desiredLongDate

# b) Machine‑wide (ControlSet001)
$cs1 = 'HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\CommonGlobUserSettings'
Set-RegistryStringValue `
    -Hive $cs1 `
    -SubKeyPath '\Control Panel\International' `
    -ValueName 'sLongDate' `
    -ValueData $desiredLongDate

# c) SID S-1-5-19 (SYSTEM)
$systemSID = 'HKEY_USERS\S-1-5-19'
Set-RegistryStringValue `
    -Hive $systemSID `
    -SubKeyPath '\Control Panel\International' `
    -ValueName 'sLongDate' `
    -ValueData $desiredLongDate

# d) SID S-1-5-20 (LOCAL SERVICE)
$localSvcSID = 'HKEY_USERS\S-1-5-20'
Set-RegistryStringValue `
    -Hive $localSvcSID `
    -SubKeyPath '\Control Panel\International' `
    -ValueName 'sLongDate' `
    -ValueData $desiredLongDate

# ────────────────────────────────────────────────────────
# 4. Apply the change immediately – restart Explorer
# ────────────────────────────────────────────────────────
Stop-Process -Name explorer.exe -Force -ErrorAction SilentlyContinue
Start-Process explorer.exe

Write-Host "All four registry locations updated to '$desiredLongDate'." `
          -ForegroundColor Green
Start-Sleep -Seconds 2

# SIG # Begin signature block
# MIIFuwYJKoZIhvcNAQcCoIIFrDCCBagCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU3qB3DCkO4jiG0iGo40olWICJ
# cNWgggM8MIIDODCCAiCgAwIBAgIQVc1z35+8BY5JQpb70tzgIDANBgkqhkiG9w0B
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
# BAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUOxvWmZma8o+lFl7hWRAVRhHgYIgwDQYJ
# KoZIhvcNAQEBBQAEggEAVvB9MqNhdDzIm8nLKxmVob7r7+vZWV0Ys+ZLpXil+C+P
# ttfkhwZP3IC0u+o3NoHM6Kiye3W6aQSgOdpW5QDQcV/+OfcSXKeLwm0odqWdYxyV
# eUHTOIX0CWYydXuDdS1H3lZnZ2hv8auO0VDwYcNdkiasbLVQS/rtZLzn6lspZrPv
# c50dmvL/sr+376MLNKiPnUIzZ1xe7tn6HFTo16q5jH1vQy+Hfjnig1LTxSfzC6Ww
# iyKJEqgcI1zTzdAHiPmg/zLFLOVvSFjRn3TIYoKWaJJ3aABCanjLBJxnru47weEq
# AyTA2/Zk+zl/Nnf0aAB2bt35Np81hTl0SlZUJrktdw==
# SIG # End signature block
