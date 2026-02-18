#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Toggles Windows sound services (enable/disable) based on user input.
.DESCRIPTION
    Toggles Windows sound services (enable/disable) based on user input.
.PARAMETER None
.EXAMPLE
    .\ToggleWindowsSound.ps1
#>

#region ----------  CONFIGURATION ----------
$AudioServices = @(
    'Audiosrv',          # Windows Audio
    'AudioEndpointBuilder'   # Alias for WMAAECN on some OS
)

$LogRoot   = 'C:\scripts\reports'
$LogFile   = Join-Path $LogRoot "$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').log"
#endregion ----------

#region ----------  LOGGING HELPERS ----------
function Write-Log {
    param([string]$Message, [ConsoleColor]$Color = 'White')
    # Console output
    Write-Host $Message -ForegroundColor $Color
    # File output (append)
    Add-Content -Path $LogFile -Value "$(Get-Date -Format o) | $Message"
}

function Ensure-LogFolder {
    if (-not (Test-Path -LiteralPath $LogRoot)) {
        New-Item -ItemType Directory -Path $LogRoot | Out-Null
        Write-Log "Created log folder: $LogRoot" -Color Green
    }
}
#endregion ----------

#region ----------  MAIN SCRIPT ----------
# Make sure the log folder exists
Ensure-LogFolder

Write-Log "=== Starting Toggle-WindowsSound ==="

# --------------------------------------------------
# 1. Check current status of each service
# --------------------------------------------------
$serviceStatus = foreach ($svc in $AudioServices) {
    try {
        $s = Get-Service -Name $svc -ErrorAction Stop
        [pscustomobject]@{
            Service     = $s.Name
            DisplayName = $s.DisplayName
            Status      = $s.Status
        }
    } catch {
        # Service not found / error
        Write-Log "ERROR: Could not get service '$svc': $_" -Color Red
        [pscustomobject]@{
            Service     = $svc
            DisplayName = 'Service not installed'
            Status      = 'NotInstalled'
        }
    }
}

# Show table on console and log it
Write-Log "`nCurrent Windows audio services status:" -Color Cyan
$serviceStatus | Format-Table -AutoSize | Out-String | Write-Log

# --------------------------------------------------
# 2. Prompt user for action
# --------------------------------------------------
function Prompt-YesNo ($question) {
    do {
        $ans = Read-Host "$question (Y/N, <Enter> to cancel)"
        if ([string]::IsNullOrWhiteSpace($ans)) { return $null }  # cancel
        if ($ans -match '^[yY]$') { return $true }
        elseif ($ans -match '^[nN]$') { return $false }
        else { Write-Warning "Please answer Y or N, or press Enter to abort." }
    } while ($true)
}

$action = Prompt-YesNo "Do you want to enable (Y) or disable (N) Windows Sound?"
if ($action -eq $null) {
    Write-Log "User aborted the operation (pressed <Enter>). Exiting..." -Color Yellow
    exit 0
}
elseif ($action) {
    Write-Log "User chose: ENABLE Audiosrv" -Color Green
} else {
    Write-Log "User chose: DISABLE Audiosrv" -Color Yellow
}

$enable = Prompt-YesNo "Do you want to enable all listed audio services?"
if ($enable) {
    Write-Log "User chose: ENABLE services" -Color Green
} else {
    Write-Log "User chose: DISABLE services" -Color Yellow
}

# --------------------------------------------------
# 3. Perform the requested action
# --------------------------------------------------
foreach ($svc in $AudioServices) {
    try {
        $s = Get-Service -Name $svc -ErrorAction Stop

        if ($enable) {
            if ($s.Status -ne 'Running') {
                Write-Log "Starting service '$($s.DisplayName)'..." -Color Green
                Start-Service -InputObject $s -ErrorAction Stop
                Write-Log "Service '$($s.DisplayName)' started successfully." -Color Green
            } else {
                Write-Log "'$($s.DisplayName)' is already running." -Color Yellow
            }
        } else {  # disable
            if ($s.Status -ne 'Stopped') {
                Write-Log "Stopping service '$($s.DisplayName)'..." -Color Red
                Stop-Service -InputObject $s -Force -ErrorAction Stop
                Write-Log "Service '$($s.DisplayName)' stopped successfully." -Color Red
            } else {
                Write-Log "'$($s.DisplayName)' is already stopped." -Color Yellow
            }
        }
    } catch {
        Write-Log "ERROR: Could not process service '$svc': $_" -Color Red
    }
}

Write-Log "`n=== Finished Toggle-WindowsSound ==="
#endregion ----------

#region ----------  WAIT FOR USER ----------
Write-Host "`nOperation completed. Press any key to exit."
[void][System.Console]::ReadKey()

# SIG # Begin signature block
# MIIFuwYJKoZIhvcNAQcCoIIFrDCCBagCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUr2hRKl3xd97fGyqHMn0Q7Bz1
# af2gggM8MIIDODCCAiCgAwIBAgIQVc1z35+8BY5JQpb70tzgIDANBgkqhkiG9w0B
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
# BAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUcqAeTAjZqZxSDQ4KbYeZM4I6BNYwDQYJ
# KoZIhvcNAQEBBQAEggEAHjRIU2Gk/pDqQDK30HRQedsTLq24CNby6/cFmEBGrcMW
# KELwvnYn3ubZ6tVNR726wAIFtRoAZFqKF8e8pmAsVJ55Tvmgxeeh2sFKF8R6boVZ
# AtufW3uAEAUxXdKob2P36h3hyfsR536+fCbolDSbPslpAQzbLIDk6Uh35m2p+i1S
# mps5YfO06HIk65/zjmqhWfDZgv4rtLZlWIcNlRAM4M0VlkV0XBdl3t7Ud4vthUiW
# SBsHgycX0vNYIff+ccAobnzm0gXewwRkMNpmNREpK9lAjGLs/RQoCGgOv4wmGmXM
# 6MDe/M17G20lXANEEvCw5reavnhMQnKBM+WpU7wBEw==
# SIG # End signature block
