<# 
.SYNOPSIS
    Toggle Windows printing core services, optional features, and a firewall rule.

.DESCRIPTION
    Run with -Enable or -Disable to set the state explicitly.
    Running without parameters checks the Spooler status,
    prompts the user, and toggles based on the current state.

.PARAMETER Action
    'Enable' | 'Disable'

.PARAMETER Quiet
    Suppress informational output (only warnings & errors are shown).

.EXAMPLE
    .\Toggle-PrintingServices.ps1 -Enable

.NOTES
    Requires PowerShell 5.0+ (for NetFirewallRule cmdlets).
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
param(
    [Parameter(Position = 0)]
    [ValidateSet('Enable','Disable')]
    [string]$Action,

    [switch]$Quiet
)

function Write-Info {
    param([string]$Message)
    if (-not $Quiet) { Write-Host $Message -ForegroundColor Cyan }
}

# --------------------------------------------------------------------
# Helper: Get or create a NetFirewallRule by DisplayName
# --------------------------------------------------------------------
function Get-FirewallRule {
    param([string]$DisplayName)
    return Get-NetFirewallRule -DisplayName $DisplayName -ErrorAction SilentlyContinue
}

function New-PrinterFirewallRule {
    param(
        [Parameter(Mandatory)][string]$DisplayName,
        [int[]]$LocalPorts = @(515, 9100)   # array for flexibility
    )
    $portString = ($LocalPorts | ForEach-Object { $_ }) -join ','

    if (-not (Get-FirewallRule -DisplayName $DisplayName)) {
        New-NetFirewallRule `
            -DisplayName $DisplayName `
            -Direction Inbound `
            -Action Allow `
            -Protocol TCP `
            -LocalPort $portString `
            -Profile Any | Out-Null
        Write-Info "- Added firewall rule '$DisplayName'"
    } else {
        Write-Info "- Firewall rule '$DisplayName' already exists"
    }
}

function Remove-PrinterFirewallRule {
    param([string]$DisplayName)
    $rule = Get-FirewallRule -DisplayName $DisplayName
    if ($rule) {
        Remove-NetFirewallRule -InputObject $rule | Out-Null
        Write-Info "- Removed firewall rule '$DisplayName'"
    } else {
        Write-Info "- Firewall rule '$DisplayName' not found"
    }
}

# --------------------------------------------------------------------
# Core service handling
# --------------------------------------------------------------------
function Set-CoreService {
    param(
        [Parameter(Mandatory)][string]$Name,
        [switch]$Enable
    )
    $svc = Get-Service -Name $Name -ErrorAction SilentlyContinue
    if (-not $svc) { Write-Warning "Service '$Name' not found."; return }

    try {
        if ($Enable) {
            if ($svc.Status -ne 'Running') {
                Start-Service -InputObject $svc -ErrorAction Stop
                Set-Service  -InputObject $svc -StartupType Automatic -ErrorAction Stop
                Write-Info "- Started & set '$Name' to Automatic"
            } else { Write-Info "- Service '$Name' already running" }
        } else {
            if ($svc.Status -ne 'Stopped') {
                Stop-Service -InputObject $svc -Force -ErrorAction Stop
                Set-Service  -InputObject $svc -StartupType Manual -ErrorAction Stop
                Write-Info "- Stopped & set '$Name' to Manual"
            } else { Write-Info "- Service '$Name' already stopped" }
        }
    } catch {
        Write-Warning "Failed to change service '$Name': $_"
    }
}

# --------------------------------------------------------------------
# Enable / Disable functions
# --------------------------------------------------------------------
function Enable-PrintServices {
    Write-Info "`n=== Enabling Windows Printing Services ==="

    # 1. Core printing services
    @('Spooler','PrintNotify','PrintDeviceConfigurationService') |
        ForEach-Object { Set-CoreService -Name $_ -Enable }

    # 2. Optional features (LPD/LPR)
    foreach ($feature in @(
            'Printing-Foundation-LPDPrintService',
            'Printing-Foundation-LPRPortMonitor'
        )) {
        if ((Get-WindowsOptionalFeature -Online -FeatureName $feature).State -ne 'Enabled') {
            Enable-WindowsOptionalFeature -Online `
                -FeatureName $feature -All -NoRestart | Out-Null
            Write-Info "- Enabled $feature"
        } else { Write-Info "- Feature '$feature' already enabled" }
    }

    # 3. Firewall rule for inbound LPD/RAW traffic
    New-PrinterFirewallRule -DisplayName 'PrinterIn-LPD-RAW'

    Write-Host "All services are now enabled." -ForegroundColor Green
}

function Disable-PrintServices {
    Write-Info "`n=== Disabling Windows Printing Services ==="

    # 1. Core printing services
    @('Spooler','PrintNotify','PrintDeviceConfigurationService') |
        ForEach-Object { Set-CoreService -Name $_ }

    # 2. Optional features
    foreach ($feature in @(
            'Printing-Foundation-LPDPrintService',
            'Printing-Foundation-LPRPortMonitor'
        )) {
        if ((Get-WindowsOptionalFeature -Online -FeatureName $feature).State -eq 'Enabled') {
            Disable-WindowsOptionalFeature -Online `
                -FeatureName $feature -All -NoRestart | Out-Null
            Write-Info "- Disabled $feature"
        } else { Write-Info "- Feature '$feature' already disabled" }
    }

    # 3. Remove firewall rule
    Remove-PrinterFirewallRule -DisplayName 'PrinterIn-LPD-RAW'

    Write-Host "All services have been disabled." -ForegroundColor Yellow
}

# --------------------------------------------------------------------
# Main logic – handle the “no‑parameter” case
# --------------------------------------------------------------------
if (-not $Action) {
    # No parameter supplied → inspect Spooler status
    $spooler = Get-Service -Name 'Spooler' -ErrorAction SilentlyContinue

    if ($null -eq $spooler) {
        Write-Warning "The Spooler service could not be found."
        exit 1
    }

    Write-Host "`nCurrent status of the Windows Spooler service: $($spooler.Status)"

    # Prompt – safe in interactive mode only
    if ($host.UI.SupportsVirtualTerminal) {
        $prompt = Read-Host "Do you want to toggle all printing services? (Y/N)"
        if ($prompt -match '^[yY]') {
            $Action = if ($spooler.Status -eq 'Running') { 'Disable' } else { 'Enable' }
        } else {
            Write-Host "Operation cancelled."
            exit 0
        }
    } else {
        # Non‑interactive – default to disabling (or whatever you prefer)
        $Action = 'Disable'
    }
}

# --------------------------------------------------------------------
# Execute the chosen action
# --------------------------------------------------------------------
switch ($Action) {
    'Enable' { Enable-PrintServices }
    'Disable'{ Disable-PrintServices }
}

# SIG # Begin signature block
# MIIFuwYJKoZIhvcNAQcCoIIFrDCCBagCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUW9RRCaAH16FZFq/azElNcVEi
# tJCgggM8MIIDODCCAiCgAwIBAgIQVc1z35+8BY5JQpb70tzgIDANBgkqhkiG9w0B
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
# BAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUUY2dbb8igVXxcydGkp3XzqJd07QwDQYJ
# KoZIhvcNAQEBBQAEggEAl9aFccIGFp5Ej6okzNY2SzQyIXsLgUHqpT3naGpGEwNc
# ZYzEW1HSPc87WHrxlu5fQRLv1hHM06/8X1U2HFJlA1w56U9M6P1tQ0Od8wCOZfKL
# kKRLnUp0824QhbcPjOp6U9H7fKVVUbEnr++gAmLQgMY3VDUI9dSXb1vBUuZC2iwZ
# 5dBb3oslRZMjY1mEDy6wW4xDu/afezH+eOI3+98Q5ajfOsXyIjFTFAj+szsalmma
# d6kufYZTXgIZ9Pdi2kTD5cFKiQbgObqlxSp+8Jy/0de4tAB8+xr5mh/gtf4aeyw7
# TzlkP90Y+wi27kYQke+64Z5m75Q1Pl5uY5LpawMcTg==
# SIG # End signature block
