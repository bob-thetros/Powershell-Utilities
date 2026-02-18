<#
.SYNOPSIS
Toggles ReadyBoost settings via the registry.
.DESCRIPTION
This script checks the current ReadyBoost status and allows the user to enable or disable it interactively. The changes are applied to the registry.
.PARAMETER 
None
.EXAMPLE
C:\> .\ToggleReadyBoost.ps1
#>


function Get-ReadyBoostStatus {
    # 1 = enabled, 4 = disabled (CacheStatus)
    $emdmPath   = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\EMDMgmt'
    $rdyPath    = 'HKLM:\SYSTEM\CurrentControlSet\Services\rdyboost'

    if (Test-Path "$emdmPath") {
        return Get-ItemPropertyValue -Path $emdmPath -Name CacheStatus
    }
    elseif (Test-Path "$rdyPath") {
        $start = Get-ItemPropertyValue -Path $rdyPath -Name Start
        return if ($start -eq 3) {1} else {4}
    }
    return $null   # key not present
}

function Set-ReadyBoostStatus($desired) {
    $emdmPath = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\EMDMgmt'
    $rdyPath  = 'HKLM:\SYSTEM\CurrentControlSet\Services\rdyboost'

    if (Test-Path "$emdmPath") {
        Set-ItemProperty -Path $emdmPath -Name CacheStatus -Value $desired -Type DWord
    }
    elseif (Test-Path "$rdyPath") {
        # Convert 1/4 to Start=3/4
        $startVal = if ($desired -eq 1) {3} else {4}
        Set-ItemProperty -Path $rdyPath -Name Start -Value $startVal -Type DWord
    }
    else {
        # Key does not exist – create it under EMDMgmt (default to enabled)
        New-ItemProperty -Path $emdmPath -Name CacheStatus -Value 1 -PropertyType DWord | Out-Null
    }
}

# ----------------------------------------------------------------------

$current = Get-ReadyBoostStatus

if ($null -eq $current) {
    Write-Host "ReadyBoost registry key not found. A default entry will be created." -ForegroundColor Yellow 
    $current = 1   # assume enabled for display purposes
}

$stateStr = if ($current -eq 1) {'Enabled'} else {'Disabled'}
Write-Host "`nCurrent ReadyBoost state: $stateStr" -ForegroundColor Cyan

# Ask the user what to do
Write-Host "Choose an action:" -ForegroundColor Yellow
Write-Host "  [E]nable ReadyBoost"
Write-Host "  [D]isable ReadyBoost"
Write-Host "  [S]kip (no change)"
$choice = Read-Host "Enter E/D/S"

switch ($choice.ToUpper()) {
    'E' { $desired = 1 }
    'D' { $desired = 4 }
    default {
        Write-Host "No changes made. Exiting." -ForegroundColor Green
        exit 0
    }
}

# If the desired state is already set, nothing to do
if ($current -eq $desired) {
    Write-Host "ReadyBoost is already in the desired state. No action taken." -ForegroundColor Green
}else {
    Write-Host "Changing ReadyBoost state to $desired." -ForegroundColor Yellow
    # Apply the change
    Set-ReadyBoostStatus $desired

}   


$newState = if ($desired -eq 1) {'enabled'} else {'disabled'}
Write-Host "ReadyBoost has been $newState." -ForegroundColor Green


# SIG # Begin signature block
# MIIFuwYJKoZIhvcNAQcCoIIFrDCCBagCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUr1fXg/K1mJ//uKfrkNpTR/0X
# O9GgggM8MIIDODCCAiCgAwIBAgIQVc1z35+8BY5JQpb70tzgIDANBgkqhkiG9w0B
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
# BAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUkg0A7vmjqWbHVwFY4C9zYnltvWAwDQYJ
# KoZIhvcNAQEBBQAEggEAnEFtNtMemfpZOeXTB1balHMslYAczlX81UyOyFSa+Y6e
# U9L/1DVHiZWJFIk0KpfQ2nE5rc1g9jpxZHDr7u2E4iRw5iKgdfxUvbqpOycbFrPB
# VlVGYmbc81LCne2+squDpfmzcHyYLtIAkItmuShYsC6PaqeWeKSGwNBuBXqbERSw
# DgCOSRoSfN3Z/d5nVzZZYDJuLvkWX7U1d+JKH/Fw2ZBdyAfK3FsnREOtWJ2O8HEw
# +nunwJepQR/n5mZzUl89/Up7++xORLf4rylTDG57iAjLT3gCFaplgPZEoV4sw0RW
# D4kHTALESIcVZnU+L66egf4W/jTYoyIZXySa6Qvgag==
# SIG # End signature block
