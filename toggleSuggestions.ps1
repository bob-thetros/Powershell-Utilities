#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Disables various types of suggestions and targeted content in Windows 10/11.

.DESCRIPTION
Modifies several Registry keys to turn off common Windows suggestions
    in areas like the Start Menu, Lock Screen, Notifications, and personalized advertising.
.PARAMETER 
None
.EXAMPLE
C:\> .\toggleSuggestions.ps1
#>

#region ── Global Variables ───────────────────────────────────────────────

# ------------------------------------------------------------------
# Registry paths
# ------------------------------------------------------------------
$ContentDeliveryPath  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
$CloudContentPolicyPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent'
$AdvertisingInfoPath   = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo'
$PrivacyPath           = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy'
$SearchSettingsPath    = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings'

# ------------------------------------------------------------------
# Keys to modify
# ------------------------------------------------------------------
$ContentDeliveryKeys  = @(
    'SubscribedContent-3383847Enabled',
    'SubscribedContent-3383850Enabled',
    'SubscribedContent-3536707Enabled',
    'OemPreInstalledAppsEnabled',
    'SoftLandingEnabled',
    'SystemPaneSuggestionsEnabled'
)

$CloudContentPolicyKeys = @{
    DisableWindowsConsumerFeatures  = 1
    DisableWindowsSpotlightFeatures = 1
}

#endregion ────────────────────────────────────────────────────────────────

#region ── Logging helpers ───────────────────────────────────────────────

$LogBase   = 'C:\scripts\reports'
$DateStamp = Get-Date -Format 'yyyyMMdd-HHmmss'

# If you want to use the same installer name as before, replace $installerName
# with a static string or supply it as an argument.
$installerName = 'WindowsSuggestions'          # <-- change if needed

$LogFile   = Join-Path $LogBase "$($env:COMPUTERNAME)-$($installerName)-$DateStamp.txt"

function Write-Log {
    param(
        [Parameter(Mandatory)][string]$Message,
        [ValidateSet('INFO','WARN','ERROR')][string]$Level='INFO'
    )
    $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $entry = "$ts [$Level] $Message"
    Add-Content -Path $LogFile -Value $entry
}

# Create log folder if it doesn't exist
if (-not (Test-Path $LogBase)) {
    New-Item -ItemType Directory -Path $LogBase | Out-Null
    Write-Log "Created log directory: $LogBase"
}

#endregion ────────────────────────────────────────────────────────────────

#region ── Helper functions ───────────────────────────────────────────────

function Get-RegValue ($path, $name) {
    try { (Get-ItemProperty -Path $path -Name $name -ErrorAction Stop).$name }
    catch { return 'N/A' }   # key / value does not exist
}

function Set-RegValue ($path,$name,$value,$force=$true) {
    if ($force) {
        New-Item -Path $path -Force | Out-Null  # create path if missing
        Set-ItemProperty -Path $path -Name $name -Value $value -Force
    } else { Set-ItemProperty -Path $path -Name $name -Value $value }
}

#endregion ────────────────────────────────────────────────────────────────

#region ── Function: Disable-WindowsSuggestions ───────────────────────────

function Disable-WindowsSuggestions {
    [CmdletBinding()]
    param()

    Write-Host "=== Disabling Windows Suggestions ===" -ForegroundColor Cyan
    Write-Log 'Starting suggestion‑disabling routine.'

    # ------------------------------------------------------------------
    # 1. Start Menu & Content Delivery
    # ------------------------------------------------------------------
    Write-Host "`n--- Start Menu / Content Delivery ---" -ForegroundColor Yellow
    foreach ($key in $ContentDeliveryKeys) {
        $current = Get-RegValue -path $ContentDeliveryPath -name $key

        Write-Host "Current value of `$($key)` : $current"
        Write-Log "Current value of '$key' : $current"

        $choice = Read-Host "Set '$key' to 0 (disable) or 1 (enable)? [0/1]"
        if ($choice -notin @('0','1')) { $choice = '0' }   # default to disable

        try {
            Set-RegValue -path $ContentDeliveryPath -name $key -value ([int]$choice)
            Write-Host "  Set '$key' to $choice." -ForegroundColor Green
            Write-Log "Set '$key' to $choice."
        } catch { 
            Write-Warning "  Could not set '$key': $_"
            Write-Log "Failed to set '$key': $_" 'ERROR'
        }
    }

    # ------------------------------------------------------------------
    # 2. Cloud Content Policy (Consumer / Spotlight)
    # ------------------------------------------------------------------
    Write-Host "`n--- Cloud Content Policy ---" -ForegroundColor Yellow
    foreach ($kvp in $CloudContentPolicyKeys.GetEnumerator()) {
        $current = Get-RegValue -path $CloudContentPolicyPath -name $kvp.Key

        Write-Host "Current value of `$($kvp.Key)` : $current"
        Write-Log "Current value of '$($kvp.Key)' : $current"

        $choice = Read-Host "Set '$($kvp.Key)' to 1 (disable) or 0 (enable)? [1/0]"
        if ($choice -notin @('0','1')) { $choice = '1' }   # default to disable

        try {
            Set-RegValue -path $CloudContentPolicyPath -name $kvp.Key -value ([int]$choice)
            Write-Host "  Set '$($kvp.Key)' to $choice." -ForegroundColor Green
            Write-Log "Set '$($kvp.Key)' to $choice."
        } catch {
            Write-Warning "  Could not set '$($kvp.Key)': $_"
            Write-Log "Failed to set '$($kvp.Key)': $_" 'ERROR'
        }
    }

    # ------------------------------------------------------------------
    # 3. Advertising ID
    # ------------------------------------------------------------------
    Write-Host "`n--- Advertising ID ---" -ForegroundColor Yellow
    $current = Get-RegValue -path $AdvertisingInfoPath -name 'Enabled'
    Write-Host "Current value of `Enabled` : $current"
    Write-Log "Current value of 'Enabled' : $current"

    $choice = Read-Host "Set Advertising ID Enabled to 0 (disable) or 1 (enable)? [0/1]"
    if ($choice -notin @('0','1')) { $choice = '0' }

    try {
        Set-RegValue -path $AdvertisingInfoPath -name 'Enabled' -value ([int]$choice)
        Write-Host "  Set Advertising ID Enabled to $choice." -ForegroundColor Green
        Write-Log "Set Advertising ID Enabled to $choice."
    } catch { 
        Write-Warning "  Could not set Advertising ID: $_"
        Write-Log "Failed to set Advertising ID: $_" 'ERROR'
    }

    # ------------------------------------------------------------------
    # 4. Tailored Experiences
    # ------------------------------------------------------------------
    Write-Host "`n--- Tailored Experiences ---" -ForegroundColor Yellow
    $current = Get-RegValue -path $PrivacyPath -name 'TailoredExperiencesWithDiagnosticDataEnabled'
    Write-Host "Current value : $current"
    Write-Log "Current value of TailoredExperiencesWithDiagnosticDataEnabled : $current"

    $choice = Read-Host "Set to 0 (disable) or 1 (enable)? [0/1]"
    if ($choice -notin @('0','1')) { $choice = '0' }

    try {
        Set-RegValue -path $PrivacyPath -name 'TailoredExperiencesWithDiagnosticDataEnabled' -value ([int]$choice)
        Write-Host "  Set to $choice." -ForegroundColor Green
        Write-Log "Set TailoredExperiencesWithDiagnosticDataEnabled to $choice."
    } catch {
        Write-Warning "  Could not set: $_"
        Write-Log "Failed to set TailoredExperiencesWithDiagnosticDataEnabled: $_" 'ERROR'
    }

    # ------------------------------------------------------------------
    # 5. Search Highlights
    # ------------------------------------------------------------------
    Write-Host "`n--- Search Highlights ---" -ForegroundColor Yellow
    $current = Get-RegValue -path $SearchSettingsPath -name 'IsContentStatusSettingEnabled'
    Write-Host "Current value : $current"
    Write-Log "Current value of IsContentStatusSettingEnabled : $current"

    $choice = Read-Host "Set to 0 (disable) or 1 (enable)? [0/1]"
    if ($choice -notin @('0','1')) { $choice = '0' }

    try {
        Set-RegValue -path $SearchSettingsPath -name 'IsContentStatusSettingEnabled' -value ([int]$choice)
        Write-Host "  Set to $choice." -ForegroundColor Green
        Write-Log "Set IsContentStatusSettingEnabled to $choice."
    } catch {
        Write-Warning "  Could not set: $_"
        Write-Log "Failed to set IsContentStatusSettingEnabled: $_" 'ERROR'
    }

    # ------------------------------------------------------------------
    # Summary
    # ------------------------------------------------------------------
    Write-Host "`n=== Script Finished ===" -ForegroundColor Cyan
    Write-Log 'Script finished.'
    Write-Host "Most changes take effect after a logoff/logon or reboot." `
        -ForegroundColor Yellow
}

#endregion ────────────────────────────────────────────────────────────────

#region ── Execute ────────────────────────────────────────────────────────

Disable-WindowsSuggestions

# Pause so the user can see the final message before the window closes
Start-Sleep -Seconds 3

# SIG # Begin signature block
# MIIFuwYJKoZIhvcNAQcCoIIFrDCCBagCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU3Y1fM5WF9lqDbQbXD5rH8btT
# uSygggM8MIIDODCCAiCgAwIBAgIQVc1z35+8BY5JQpb70tzgIDANBgkqhkiG9w0B
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
# BAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUuJb88KtalGDc0NdZ2NXKemeRG2IwDQYJ
# KoZIhvcNAQEBBQAEggEAc4WPX31471o3RcyMIAHmaGMND19i8uHHUQgXgLImagFL
# JRhX2+A1hX7++Ur3V0Cn9HwtwxfRPIuAWANrCw+NOBaIYPRtfdDM8njORgT0UGnQ
# gwnax/5PMcJ0MFZseR62EMHNwmFP2wn7qcDWx2EexttaQd0neXOMN1fxDvlSS9/Z
# OV5RTg85G/J0iXZe7zJGe9XpjZoPrEXOkC/67dPn+R12GitxMDXmKqwDeF5uM9YM
# rPVEZJz4jfHfoSofmPVqKCduG5mQQAh8dXlrgvF0ZcWzA6b5cJvUxgSCKFxwNuRs
# 5bqlHOLwt2k4YWm+XlU8B246TVaokGTlvGSKmRpWLg==
# SIG # End signature block
