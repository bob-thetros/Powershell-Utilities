<#
.SYNOPSIS
Sets the Hibernation state
.DESCRIPTION
Sets the Hibernation state.
.PARAMETER None
none
.EXAMPLE
C:\> .\ToggleHibernation.ps1
#>
# Check current hibernation status safely
try {
    $hiberStatus = powercfg /a 2>&1 | Select-String "Hibernate" | ForEach-Object { $_.ToString() }
} catch {
    Write-Host "Unable to retrieve hibernation status. You may not have sufficient privileges or the system does not support hibernation."
    exit 1
}

if ($hiberStatus -match "not available" -or !$hiberStatus) {
    Write-Host "Hibernation is currently disabled."
    $choice = Read-Host "Would you like to enable hibernation? (Y/N)"
    if ($choice.ToUpper() -eq "Y") {
        Write-Host "Enabling hibernation..."
        Start-Process "powercfg.exe" -ArgumentList "/hibernate on" -Wait
        Write-Host "Hibernation has been enabled."
    } else {
        Write-Host "No changes made."
    }
} else {
    Write-Host "Hibernation is currently enabled."
    $choice = Read-Host "Would you like to disable hibernation? (Y/N)"
    if ($choice.ToUpper() -eq "Y") {
        Write-Host "Disabling hibernation..."
        Start-Process "powercfg.exe" -ArgumentList "/hibernate off" -Wait
        Write-Host "Hibernation has been disabled."
    } else {
        Write-Host "No changes made."
    }
}
# SIG # Begin signature block
# MIIFuwYJKoZIhvcNAQcCoIIFrDCCBagCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUr5MjkVRDEj9r2qVgVUlo9Rbj
# o6SgggM8MIIDODCCAiCgAwIBAgIQVc1z35+8BY5JQpb70tzgIDANBgkqhkiG9w0B
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
# BAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUtrTE52fpy+hmQwYvSRZduDzZLPIwDQYJ
# KoZIhvcNAQEBBQAEggEASRAt5eYBb7wiBkyc2RY7oRbyvfDWzZxVFWoASAJKOF7X
# v8RyCyyrj5kZs8yTz51gGAMv0T0PohSMLNRQdp+PSqSbPNDIyHrjKCTKd7/uBd9n
# VI8JP4q5BzSE08606uhLrNlP0qW1LiAOirQ9HiwRNscwlqgDncId+3TI/C3lpqG7
# B9fl3xbY3bHv8TCC65fTxyXGWjfch4GS3Wjcgdm2XsqniW2B7qiQ9jEyOxsGRF2R
# aJAEXgZ6L0spJev3QQIMqkKFW2w2206klFqwdVzAnJrha2MHtsyF7Gf+ENQSqmUX
# ACmyfh6sfao54TUc4eOodu2RnrETb/G6GN0/LOFMJw==
# SIG # End signature block
