#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Adds all ARP entries to the Windows hosts file.

.DESCRIPTION
    The script obtains the current ARP table, then for each entry it writes a line in
    %SystemRoot%\System32\drivers\etc\hosts of the form

        <IP> host#   MAC: <MAC>

    If an IP already exists in the hosts file it is replaced with the new line so
    that you always end up with the most recent ARP information.

.NOTES
    Requires PowerShell v5+ (Get-NetNeighbor).  
    Run as Administrator because the hosts file is protected.
#>

# ──────────────────────── 1. SETTINGS ───────────────────────────────

$HostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
$HostNamePrefix = "host"   # will become host0, host1, …

# ──────────────────────── 2. FLUSH DNS CACHE ────────────────────────
Write-Host "Flushing DNS cache..."
ipconfig /flushdns | Out-Null  # Suppress output from ipconfig

# ──────────────────────── 2. GET ARP TABLE ────────────────────────


    $arpEntries = Get-NetNeighbor |
        Where-Object {$_.LinkLayerAddress -and $_.IPAddress -and $_.State -eq 'Reachable'} |
        Select-Object @{Name='IPAddress';Expression={$_.IPAddress}},
                      @{Name='MAC';Expression={$_.LinkLayerAddress}}

if (-not $arpEntries) {
    Write-Warning "No ARP entries found."
    exit 1
}

# ──────────────────────── 3. READ EXISTING HOSTS FILE ─────────────

# Load current lines, preserving order and comments that are *not* our generated ones.
$existingLines = Get-Content -LiteralPath $HostsPath -ErrorAction SilentlyContinue
if ($null -eq $existingLines) { $existingLines = @() }

# Build a hashtable of IP → line index for quick lookup
$ipIndexMap = @{}
for ($i=0; $i -lt $existingLines.Count; $i++) {
    $line = $existingLines[$i].Trim()
    if ($line -match '^\s*(?<ip>\d{1,3}(?:\.\d{1,3}){3})\s+(?<name>\S+)') {
        $ipIndexMap[$matches.ip] = $i
    }
}

# ──────────────────────── 4. BUILD NEW HOSTS ENTRIES ─────────────

$entriesToWrite = @()
$pound = '#'
for ($j=0; $j -lt $arpEntries.Count; $j++) {
    $entry = $arpEntries[$j]
    $ipAddress = $entry.IPAddress

    # --- TRACEROUTE and HOSTNAME RESOLUTION ---
    try {
        $tracerouteResult = tracert $ipAddress -MaximumHop 1  # Only need the first hop
        if ($tracerouteResult) {
            $hostname = $tracerouteResult[0].Hostname # Get hostname from traceroute output.
            if($hostname){
                Write-Host "Using hostname '$hostname' for IP: $ipAddress"
                $name = $hostname
            } else {
                # Inside your loop where you process ARP entries
                if ($entry.IPAddress -match '^fe80::') {
                # Skip link-local addresses entirely, or assign a default name
                    $hostname = "link_local"  # Or some other identifier
                } else {
                try {
                    $hostname = tracert $entry.IPAddress | Select-String -Pattern '(?<name>\S+)' | ForEach-Object {$_.name}
                } catch {
                    Write-Warning "Error during traceroute for IP: $ipAddress.  Using default hostname."
                    $hostname = "host"
                }
        }

                $name = "$HostNamePrefix$j"  # Fallback to default name if no hostname found
            }

        } else {
            # Traceroute failed, use the default host name.
            Write-Warning "Traceroute failed for IP: $ipAddress. Using default hostname."
            $name = "$HostNamePrefix$j"
        }
    } catch {
        # Traceroute error - use default hostname
        Write-Warning "Error during traceroute for IP: $ipAddress.  Using default hostname."
        $name = "$HostNamePrefix$j"
    }

    # --- END TRACEROUTE and HOSTNAME RESOLUTION ---


    $line   = "{0} {1}{2}  $($pound) MAC: {3}" -f `
        $ipAddress,            # IP
        $name,             # hostname from traceroute or default
        $j,                          # index
        $entry.MAC                    # MAC comment

    if ($ipIndexMap.ContainsKey($entry.IPAddress)) {
        # Replace existing line
        $existingLines[$ipIndexMap[$entry.IPAddress]] = $line
    } else {
        # Append new line
        $entriesToWrite += $line
    }
}

# If there were replacements, write the whole file back first
if ($entriesToWrite.Count -eq 0) {
    Write-Host "No changes required hosts file is up to date."
    exit 0
} else {
    # Append new entries at the end
    $existingLines += $entriesToWrite
}

# ──────────────────────── 5. WRITE BACK TO HOSTS FILE ─────────────

Set-Content -LiteralPath $HostsPath -Value $existingLines -Encoding ASCII -Force
Write-Host "Successfully updated '$HostsPath' with ARP entries."

# SIG # Begin signature block
# MIIFuwYJKoZIhvcNAQcCoIIFrDCCBagCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU4BYlp2vVNRhjIaYoxjCfK+Bh
# IPegggM8MIIDODCCAiCgAwIBAgIQVc1z35+8BY5JQpb70tzgIDANBgkqhkiG9w0B
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
# BAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQU/IOPJdFl21qvtMs1jsI/s86F5nQwDQYJ
# KoZIhvcNAQEBBQAEggEAyjegmnf4oqkESkYPvZ/agkMwpXnXyM86/+jcGvv+J+/l
# lyVz+ZlZa/pOegtunb9gxmmhdk/CRgF+WR4MEt4YCcWHpn5NeguemeBsGEPg0y7T
# aAd6M3APOIs4kvsvHfPA/jQ6yvDY7iQc+JPZ406N1LQ46Z5tyMjMC4nm2aoiAr9q
# fgg5yOE5PsOBoXMB6Kb2w03HVxLt+J83u9Ts3a1TVNcKnLt0z/3KewRoF4CgLUHA
# 7TUG5Mb+9abf4tWcoVj63pic0JWhJJbMP22buizIa7s0xwL04BiT8UAYpavkY1pC
# muIatU8Yo6usCGgpILz1Z3ZwD/ttsB/qwSRGfWUi1Q==
# SIG # End signature block
