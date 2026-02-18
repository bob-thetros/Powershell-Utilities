<# 
.SYNOPSIS
    Sets the network interface metrics to prioritize a selected network adapter.
.DESCRIPTION
Sets the network interface metrics to prioritize a selected network adapter.
    The script lists all active network adapters and prompts the user to select one.
    The selected adapter is assigned the lowest metric (highest priority), and other adapters
    are assigned incrementally higher metrics.
.PARAMETER None

.EXAMPLE
    .\
.NOTES
   Requires PowerShell v5+ and that you run the console as Administrator.
#>

function Get-ActiveAdapters {
    # Use Win32_NetworkAdapter (no netsh needed for discovery)
    Get-WmiObject -Class Win32_NetworkAdapter |
        Where-Object { $_.NetEnabled -eq $true } |
        Select-Object InterfaceIndex, Name
}

function Show-Adapters ($adapters) {
    Write-Host "`nActive network adapters:" -ForegroundColor Cyan
    $i = 1
    foreach ($a in $adapters) {
        Write-Host "$i. $($a.Name)" `
                 " (Index: $($a.InterfaceIndex))"
        $i++
    }
}

function Prompt-Choice ($count) {
    while ($true) {
        $choice = Read-Host "`nEnter the *number* of the adapter that should get metric 1 (0 to abort)"
        if ([int]::TryParse($choice, [ref]$null)) {
            if ($choice -eq 0) { return 0 }          # abort
            if ($choice -ge 1 -and $choice -le $count) { return $choice }
        }
        Write-Warning "Please enter a valid number between 0 and $count."
    }
}

function Set-Metrics ($adapters, $chosenIndex) {
    # The metric values we will assign
    $metric = 1

    foreach ($adapter in $adapters | Sort-Object -Property Name) {
        if ($adapter.InterfaceIndex -eq $chosenIndex) {
            netsh interface ipv4 set subinterface "$($adapter.Name)" metric=$metric
            Write-Host "Set metric $metric on '$($adapter.Name)' (Index $($adapter.InterfaceIndex))"
        }
        else {
            netsh interface ipv4 set subinterface "$($adapter.Name)" metric=$metric
            Write-Host "Set metric $metric on '$($adapter.Name)' (Index $($adapter.InterfaceIndex))"
        }
        $metric++   # next adapter gets one higher
    }
}

function Show-RoutingTable {
    Write-Host "`nRouting table after changes:" -ForegroundColor Green
    route print | Out-String | Write-Host
}

# --------------------------------------------------------------------------- #
# MAIN SCRIPT

$adapters = Get-ActiveAdapters
if ($adapters.Count -eq 0) {
    Write-Warning "No active adapters found. Exiting."
    exit
}

Show-Adapters $adapters
$choiceNum = Prompt-Choice $adapters.Count

if ($choiceNum -eq 0) {
    Write-Host "`nAbort selected – no changes made." -ForegroundColor Yellow
    exit
}

$chosenAdapter = $adapters[$choiceNum - 1]

Set-Metrics $adapters $chosenAdapter.InterfaceIndex

Show-RoutingTable

# SIG # Begin signature block
# MIIFuwYJKoZIhvcNAQcCoIIFrDCCBagCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUUxQuAunHZjW02YfM2cfNXkH6
# M82gggM8MIIDODCCAiCgAwIBAgIQVc1z35+8BY5JQpb70tzgIDANBgkqhkiG9w0B
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
# BAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUX40aZUpLrdDWMA4NVpz4Z8bL5sEwDQYJ
# KoZIhvcNAQEBBQAEggEAAxlFc/F2QBLuqe2myx/1a8CH70zkAO2/SRZZ3X5rJk+C
# VMMioudE0pAeCxCO8f8ivMKBuiaZ8sIVmm7FoZy9rKHwIkw5RhUy+KbVmmNb+jWi
# 32/rtnkH1AMpK/IgW8z8XdzSE8KmoYnHPkqC+q81ofKE0q6VDByCH0VwzOVK3So3
# 2GNUwbEzmwOVomp0nUCYVHGIWpyyeri1zpKDzDSgh0gjuXWC6RiUBpJ46mF/W45T
# CFWSYD1KtQe8vvDT03OLPgzgWsERcKPgbBkqRhkIqjkLMyWDw3dSZVqmsyBO/PPb
# PuR0bILksC3cq9ls/L5Lyly2pLIKkRDZ5hBbYmENng==
# SIG # End signature block
