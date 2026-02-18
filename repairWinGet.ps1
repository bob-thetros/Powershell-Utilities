#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Installs or repairs the Windows Package Manager (WinGet) on the local machine.
.DESCRIPTION
    Installs or repairs the Windows Package Manager (WinGet) using the Microsoft.WinGet.Client PowerShell module.
.PARAMETER None
.EXAMPLE
    .\repairWinGet.ps1
#>
function Check-Internet {
    try{
        $TestConnection = Test-Connection -ComputerName 8.8.8.8 -Count 2 -ErrorAction Stop
        Write-Host "Online" -ForegroundColor Cyan
        Write-Log "Online" 'INFO'
    } catch {
        Write-Host "Offline unable to continue with installer." -ForegroundColor Red
        Write-Log "Offline unable to continue." 'INFO'
        Start-Sleep -Seconds 2
        exit 1
    }
}

$cmd = Get-Command winget.exe -ErrorAction SilentlyContinue
    if ($cmd) {
        Write-host "Repair winget not needed."
        Start-Sleep -Milliseconds 2000
        exit 0
    }
Check-Internet
$progressPreference = 'silentlyContinue'
Write-Host "Installing WinGet PowerShell module from PSGallery..."
Install-PackageProvider -Name NuGet -Force | Out-Null
Install-Module -Name Microsoft.WinGet.Client -Force -Repository PSGallery | Out-Null
Write-Host "Using Repair-WinGetPackageManager cmdlet to bootstrap WinGet..."
Repair-WinGetPackageManager -AllUsers
Write-Host "Done."
# SIG # Begin signature block
# MIIFuwYJKoZIhvcNAQcCoIIFrDCCBagCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUPOjA1QUY7LgA8+F1rq68BCF2
# p/6gggM8MIIDODCCAiCgAwIBAgIQVc1z35+8BY5JQpb70tzgIDANBgkqhkiG9w0B
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
# BAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUvazmLY+Va/itSoa0UQJUT+K2BMowDQYJ
# KoZIhvcNAQEBBQAEggEAlURgO3xxqFQiUZ9tTmZyf3d43Nws/A4td0v6JPLNpF8/
# DyKQ6PZd532ma8eLSo4z3GWt7LgmeVfWMDg4ZSDPjrjKiGOxBQ3cRIRWJNLequhk
# ubaEAPZSMa0ckIig3N1ULNUJk7DUlHx1rCxEKXiBAkDq7Ry4T09NciWebJo+ce7g
# r+ToLMaWY0VLD2kTfAnBDOh0bLRsvgr9G4bbUbdmAicJ+hrIPGxLx+LDHb9Sfs6J
# z1NF8WUQkC0ILHv4HvpRASicLkuxcS/Yqk4XeYkgXXVIbQWKldr0fBmA5vHZRM4l
# IrhGiAOSnpFKAeK+W8xsJeMR+90cxQZvOlYiVckMnA==
# SIG # End signature block
