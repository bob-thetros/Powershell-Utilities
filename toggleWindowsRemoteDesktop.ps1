<# 
.SYNOPSIS
Toggle Windows Remote Desktop for the current machine, automatically adjust
Networkâ€‘Level Authentication based on domain membership, and log all actions.

.DESCRIPTION
- Reads the current RDP setting and NLA state from the registry.  
- Prompts the user to toggle RDP; if disabling, optionally turns off NLA.  
- When enabling RDP, NLA is enabled *only* for domainâ€‘joined machines â€“ otherwise it is disabled automatically.  
- All actions (status reads, prompts, changes, errors) are written to a log file
  located at C:\Scripts\Reports\RDP-<yyyyMMdd>.log.

.PARAMETER none
This script does not take parameters â€“ all interaction happens in the console.

.EXAMPLE
C:\> .\ToggleWindowsRemoteDesktop.ps1
#>

#region Logging ---------------------------------------------------------------
$LogFolder = 'C:\Scripts\Reports'
if (-not (Test-Path $LogFolder)) { New-Item -ItemType Directory -Path $LogFolder | Out-Null }

function Write-Log {
    param(
        [Parameter(Mandatory=$true)][string]$Message,
        [ValidateSet('INFO','WARN','ERROR')][string]$Level = 'INFO'
    )
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logEntry  = "$timestamp [$Level] $Message"
    $logFile   = Join-Path $LogFolder ("RDP-$(Get-Date -Format 'yyyyMMdd').log")
    Add-Content -Path $logFile -Value $logEntry
}
#endregion --------------------------------------------------------------------

#region Helper functions ----------------------------------------------------
function Get-RdpStatus {
    $regPath = 'HKLM:\System\CurrentControlSet\Control\Terminal Server'
    try { (Get-ItemProperty -Path $regPath -Name fDenyTSConnections).fDenyTSConnections }
    catch {
        Write-Warning "Unable to read RDP status from the registry."
        Write-Log "Failed to read RDP status: $_" 'ERROR'
        return $null
    }
}

function Get-NlaStatus {
    $winTcp = 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp'
    try { (Get-ItemProperty -Path $winTcp -Name UserAuthentication).UserAuthentication }
    catch {
        Write-Warning "Unable to read NLA status from the registry."
        Write-Log "Failed to read NLA status: $_" 'ERROR'
        return $null
    }
}

function Is-DomainJoined {
    # DomainRole: 0=Standalone Workstation, 1=Member Workstation,
    # 2/3=Domain Controller â€“ any >0 means domainâ€‘joined.
    $role = (Get-CimInstance -ClassName Win32_ComputerSystem).DomainRole
    return ($role -gt 0)
}
function Set-RdpStatus {
    param(
        [bool]$enable,
        [switch]$DisableNLA
    )

    $regPath = 'HKLM:\System\CurrentControlSet\Control\Terminal Server'
    $winTcp  = 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp'

    try {
        # fDenyTSConnections: 0 = allow, 1 = deny
        $denyValue = if ($enable) { 0 } else { 1 }
        Set-ItemProperty -Path $regPath -Name fDenyTSConnections -Value $denyValue
        Write-Log "Set fDenyTSConnections to $denyValue"

        if ($enable) {
            # Default: enable NLA. If the computer is NOT domain‑joined, turn it off.
            if (-not (Is-DomainJoined)) {
                Set-ItemProperty -Path $winTcp -Name UserAuthentication -Value 0
                Write-Host "Non-domain machine detected – NetworkLevel Authentication has been DISABLED for compatibility."
                Write-Log "NLA disabled automatically (nondomain machine)."
            } else {
                Set-ItemProperty -Path $winTcp -Name UserAuthentication -Value 1
                Write-Log "NLA enabled (domain machine)."
            }

            # Enable the firewall rule for Remote Desktop
            Enable-NetFirewallRule -DisplayGroup 'Remote Desktop' | Out-Null

            Write-Host "`nRemote Desktop has been ENABLED successfully." `
                        -ForegroundColor Green
            Write-Log "Remote Desktop enabled."
        } else {
            if ($DisableNLA) {
                Set-ItemProperty -Path $winTcp -Name UserAuthentication -Value 0
                Write-Host "NetworkLevel Authentication has been DISABLED."
                Write-Log "NLA disabled by user request."
            }

            Write-Host "`nRemote Desktop has been DISABLED successfully." `
                        -ForegroundColor Green
            Write-Log "Remote Desktop disabled."
        }
    } catch {
        Write-Error "Failed to change RDP setting: $_"
        Write-Log "Failed to change RDP setting: $_" 'ERROR'
    }
}
#endregion --------------------------------------------------------------------
#region Main script ----------------------------------------------------------
Write-Log "Script started."

$currentStatus = Get-RdpStatus

if ($null -eq $currentStatus) {
    Write-Warning "Cannot determine current Remote Desktop status. Exiting."
    Write-Log "Unable to read current RDP status; exiting." 'ERROR'
    exit 1
}

# ----- Read & display NLA state ---------------------------------------------
$nlaStatus = Get-NlaStatus
$nlaText   = if ($nlaStatus -eq 0) { 'DISABLED' } else { 'ENABLED' }

$stateText = if ($currentStatus -eq 0) { 'ENABLED' } else { 'DISABLED' }
Write-Host "Current Remote Desktop setting: $stateText"
Write-Host "Network Level Authentication (NLA): $nlaText"

# Ask whether to toggle
$prompt = Read-Host "Do you want to toggle RemoteDesktop? (Y/N)"
if (-not ($prompt -match '^[yY]')) {
    Write-Host "Operation cancelled."
    Write-Log "User cancelled operation." 'INFO'
    exit 0
}

# Determine new state
$newEnable = $currentStatus -ne 0   # if currently disabled, enable; otherwise disable

# If disabling, ask about NLA
$disableNLA = $false
if (-not $newEnable) {
    $nlaPrompt = Read-Host "Also disable Network Level Authentication? (Y/N)"
    if ($nlaPrompt -match '^[yY]') { $disableNLA = $true }
}

# Apply the change
Set-RdpStatus -enable $newEnable -DisableNLA:$disableNLA

Write-Log "Toggle Remote Desktop set." 'INFO'
Write-Host "Toggle Remote Desktop complete." -ForegroundColor Green
Write-Log "Toggle Remote Desktop complete." 'INFO'

Start-Sleep -Milliseconds 2000
#endregion --------------------------------------------------------------------

# SIG # Begin signature block
# MIIFuwYJKoZIhvcNAQcCoIIFrDCCBagCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU/4SkNvxq3j7Ic7T5bSRrIWll
# ne+gggM8MIIDODCCAiCgAwIBAgIQVc1z35+8BY5JQpb70tzgIDANBgkqhkiG9w0B
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
# BAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUoUBjLZIFFRaiE+fmqlKEhbEZfVswDQYJ
# KoZIhvcNAQEBBQAEggEAByIY0uQXh2E8s1hGOXJJ2DvMzxRXMLxguYCwmoFb4C0s
# PZuTm9VoUhuI7kfXQ765+EqsJA0syIxAhpOJssC/KRq5hGvYisTtJN9E5uuZMsRs
# f0kFwf9qAJQjciQTRXg0gqEgZa/D8WA5hui1A2kVOv7IZj86fwo8cGVPhR/+IBBJ
# puy5vS392kteukqZ2VY9xmo6Jm5EyRPs4K6z5jcrrpcWP24r2WQwfAzJ14OIFNpk
# SUoNOEh53s6R+RhOqP5bsl4ku4JyZzS1+K7DG9eFA6ap7VjjChzeTWc/T9jRNbG2
# jlAsXTNXj5LAWoF8upFUOUYcUVtUxMvd3SnSLjgpCA==
# SIG # End signature block
