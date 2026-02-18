<#
.SYNOPSIS
    Removes selected built-in Windows applications (apps) from the system.
.DESCRIPTION
Removes built-in Windows applications (apps) that are often pre-installed on Windows systems. The user can choose to remove specific apps or all listed apps. The script logs the removal actions to a text file for reference.        
.PARAMETER none
.EXAMPLE
C:\> .\Cleanup-WindowsApps.ps1
#>

#--------------------------------------------------------------------
# Array of apps to remove (name → package filter)
$Apps = @(
    @{Name='Get Started';          Package='*getstarted*'},
    @{Name='Windows Phone Companion'; Package='*windowsphone*'},
    @{Name='Xbox';                 Package='*xboxapp*'},
    @{Name='People App';           Package='*people*'},
    @{Name='3D Builder';          Package='*3dbuilder*'},
    @{Name='Voice Recorder';      Package='*soundrecorder*'},
    @{Name='Calendar and Mail';   Package='*windowscommunicationsapps*'},
    @{Name='Alarms and Clock';   Package='*windowsalarms*'},
    @{Name='Get Office';          Package='*officehub*'},
    @{Name='OneNote';             Package='*onenote*'},
    @{Name='Bing Maps';           Package='*windowsmaps*'},
    @{Name='Bing Finance / Money';Package='*bingfinance*'},
    @{Name='Zune / Windows Video';Package='*zunevideo*'},
    @{Name='Zune / Groove Music';Package='*zunemusic*'},
    @{Name='Solitaire';           Package='*solitairecollection*'},
    @{Name='Bing Sports';          Package='*bingsports*'},
    @{Name='Bing News';            Package='*bingnews*'},
    @{Name='Bing Weather';         Package='*bingweather*'},
    @{Name='Skype App';            Package='*skypeapp*'},
    @{Name='King';                Package='*king.com*'}
)

#--------------------------------------------------------------------
# Create the log file (date in name)
$logFile = Join-Path -Path "C:\Scripts\Reports" `
              -ChildPath ("AppsRemoved_{0}.txt" -f (Get-Date -Format 'yyyyMMddHHmm'))

# Make sure the directory exists
if (-not (Test-Path -Path $logFile)) { New-Item -ItemType Directory -Path (Split-Path -Parent $logFile) }

#--------------------------------------------------------------------
# 1 Show the list with indices so you can pick one or all
Write-Host "`nAvailable apps:"

for ($i = 0; $i -lt $Apps.Count; $i++) {
    Write-Host "[$($i + 1)] $($Apps[$i].Name)"
}

# Prompt for user input – number or 'a' (all)
$choice = Read-Host -Prompt "`nWhich app to remove? (number or a)"

#--------------------------------------------------------------------
# 2️ Remove the selected app(s) – log every step
if ($choice -ieq 'a') {
    # All apps: loop over all items
    for ($i=0; $i -lt $Apps.Count; $i++) {
        Remove-ItemAndLog $i
    }
}
else {
    # One app only – convert the number to a zero‑based index
    $idx = [int]$choice - 1

    if (($idx -ge 0) -and ($idx -lt $Apps.Count)) {
        Remove-ItemAndLog $idx
    } else {
        Write-Host "  Invalid choice – nothing removed." -ForegroundColor Red
    }
}

#--------------------------------------------------------------------
# Helper function: remove the chosen item and log it
function Remove-ItemAndLog([int]$Index) {
    $app = $Apps[$Index]
    $msg = "[$($Index + 1)] Removing $($app.Name) – Package: $($app.Package)"
    Write-Host $msg
    Add-Content -Path $logFile -Value $msg

    Get-AppxPackage $app.Package | Remove-AppxPackage
}

# SIG # Begin signature block
# MIIFuwYJKoZIhvcNAQcCoIIFrDCCBagCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUcOMc4UOTH4he5cPmgT97oyoP
# 3VmgggM8MIIDODCCAiCgAwIBAgIQVc1z35+8BY5JQpb70tzgIDANBgkqhkiG9w0B
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
# BAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQU/UiG8ocyGTt4fz6gNzyhMzux4W0wDQYJ
# KoZIhvcNAQEBBQAEggEAKoVt1KlhKkE5pMIJO3bFksflDxE+plzuSyZnqdaV4xUK
# c3Kzhjjb5TrRLHOYa6xr70wtjk0gSmXC2E3fpEuO3tgpN6RRJ2i9ayKP0JnHbjiH
# h68jQerkyAoXPFRnAD1uKKU+j2phgovFoQLhIeO3+libs5Hj841nN0LtUMsDEX3T
# TWhTB7oFKp9PoRy83wTC2gZfu2C129e2tlwpZBsU3qwRukkZMPpuc+dCQvs6ho/Y
# iPwozrYO/K03eMZPLuLNuoyUinII+sZO1AgSdGciFaCNpJCoGP1ThckJ7B8g2coH
# pC2NSWx7XCpaepj4Y9RCxrW8iKxi38vzObpLmTb2Sw==
# SIG # End signature block
