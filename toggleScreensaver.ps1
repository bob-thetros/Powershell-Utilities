# ----------------------------------------------------------
# Toggle-ScreenSaver.ps1
#
# Requires:   Administrative rights (recommended but not mandatory for HKCU changes)
# Purpose:    Show current screen‑saver settings and let the user
#             toggle between a 15‑minute “require logon” configuration
#             and the values that were in place before this script ran.
#
# ----------------------------------------------------------

$ErrorActionPreference = 'Stop'

# -----------------------------------------------------------------
# Helper – read registry keys into a hashtable
function Get-CurrentScreenSaverValues {
    param([string]$RegBase)

    @{
        ScreenSaveActive      = (Get-ItemProperty -Path $RegBase -Name 'ScreenSaveActive' -ErrorAction SilentlyContinue).ScreenSaveActive
        ScreenSaveTimeOut     = (Get-ItemProperty -Path $RegBase -Name 'ScreenSaveTimeOut'  -ErrorAction SilentlyContinue).ScreenSaveTimeOut
        ScreenSaverIsSecure   = (Get-ItemProperty -Path $RegBase -Name 'Screen Saver Is Secure' -ErrorAction SilentlyContinue).'Screen Saver Is Secure'
        SCRNSAVE.EXE          = (Get-ItemProperty -Path $RegBase -Name 'SCRNSAVE.EXE' -ErrorAction SilentlyContinue).SCRNSAVE.EXE
    }
}

# -----------------------------------------------------------------
$regBase   = 'HKCU:\Control Panel\Desktop'

# Current values before we touch anything
$currentValues = Get-CurrentScreenSaverValues -RegBase $regBase

Write-Host "=== Current Screen‑Saver Settings ==="
Write-Host ("ScreenSaveActive      : {0}"  -f ($currentValues.ScreenSaveActive   ?? 'N/A'))
Write-Host ("ScreenSaveTimeOut     : {0} seconds" -f ($currentValues.ScreenSaveTimeOut  ?? 'N/A'))
Write-Host ("ScreenSaverIsSecure   : {0}"  -f ($currentValues.ScreenSaverIsSecure ?? 'N/A'))
Write-Host ("SCRNSAVE.EXE          : {0}"  -f ($currentValues.SCRNSAVE.EXE      ?? 'N/A'))
Write-Host "====================================="

# -----------------------------------------------------------------
# Decide what we want to do
$choice = Read-Host @"
Choose an action:
  [1] Set screen saver to 15 minutes (require logon)
  [2] Revert to the previous settings you just saw
  [3] Disable the screen‑saver completely
Enter 1, 2 or 3: 
"@

switch ($choice) {
    '1' { # Apply the 15‑minute configuration
        $scrnsavePath = "$env:SystemRoot\System32\scrnsave.scr"
        if (-not (Test-Path $scrnsavePath)) {
            Write-Error "Screensaver file not found: $scrnsavePath"
            exit 1
        }

        $newValues = @{
            ScreenSaveActive      = '1'
            ScreenSaveTimeOut     = '900'          # 15 minutes in seconds
            ScreenSaverIsSecure   = '1'
            SCRNSAVE.EXE          = $scrnsavePath
        }

        foreach ($k in $newValues.Keys) {
            Set-ItemProperty -Path $regBase -Name $k -Value $newValues[$k] -Force
        }
        Write-Host "Screen saver set to 15 minutes and requires logon on resume."
    }

    '2' { # Restore the original values
        foreach ($k in $currentValues.Keys) {
            if ($null -ne $currentValues.$k) {
                Set-ItemProperty -Path $regBase -Name $k -Value $currentValues.$k -Force
            }
        }
        Write-Host "Reverted to the previous screen‑saver settings."
    }

    '3' { # Disable the screensaver
        $disableValues = @{
            ScreenSaveActive      = '0'
            #ScreenSaveTimeOut     = $currentValues.ScreenSaveTimeOut   # keep existing value (optional)
            #ScreenSaverIsSecure   = $null                               # leave unchanged or clear
            #SCRNSAVE.EXE          = $null                               # leave unchanged or clear
        }

        foreach ($k in $disableValues.Keys) {
            Set-ItemProperty -Path $regBase -Name $k -Value $disableValues[$k] -Force
        }
        Write-Host "Screen saver disabled."
    }

    default {
        Write-Warning "Invalid choice – no changes made."
    }
}

# SIG # Begin signature block
# MIIFuwYJKoZIhvcNAQcCoIIFrDCCBagCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUfNodmyRvSsnI7Wf2acoR92Y+
# gcqgggM8MIIDODCCAiCgAwIBAgIQVc1z35+8BY5JQpb70tzgIDANBgkqhkiG9w0B
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
# BAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUlClw0pmGvPsItu3dGvgtEkQk9Y4wDQYJ
# KoZIhvcNAQEBBQAEggEArwjde+W3MDuojjvS5TPE09uGuQdtKwEOZls6rgWmINi0
# dEZcjBRlOs9PDFy3gi1ukaSx0F/qbL2sTxE1rbBKjaLYlcFX/CcN9/ZsXhSB1RNE
# sPGdUSgixrfh13LUDs8dwNkZ9zCo2AkbyX4mY3ObKMSHybk5HZHjw8aKAoQQQl3m
# XgbkEMB/SW0jKPQlTV5EhjWJxmifIqPwlDip0kMnK3xVXfu++d0iBbrkOiyV0NLC
# cRymJz34JbKYkfvUgnX8Dm+/Zq1tOc2DvNxrDYzVs1G44VggpGezntBhZp38ust2
# 0lAOwc3PEjkpkU3zNrFZf99NCVzZPYRfYbWSIyCY4A==
# SIG # End signature block
