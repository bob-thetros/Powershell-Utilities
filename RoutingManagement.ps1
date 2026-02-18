<# 
.SYNOPSIS
    Simple gateway blocker / restorer for Windows 10/Server (PowerShell 5.1)

.DESCRIPTION
Simple gateway blocker / restorer 
    * Option 1 – Disable the default route and replace it with your own.
    * Option 2 – Restore the original default route from a file.
    * Option 3 – Persist the change at log‑on by creating a scheduled task.

.NOTES
    Run this script **as Administrator**.  
    Requires PowerShell 5.1 (or later) and the NetTCPIP module (built‑in).
#>

# --------------------------------------------------------------------------- #
# 0. Helper: create directory if it does not exist
$BaseDir   = 'C:\Scripts'
$LogDir    = Join-Path $BaseDir 'Reports'
$DataFile  = Join-Path $BaseDir 'defaultgateway.txt'

foreach ($d in @($BaseDir, $LogDir)) {
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d | Out-Null }
}

# --------------------------------------------------------------------------- #
# 1. Get the current default gateway(s)
$Gateway = Get-CimInstance Win32_NetworkAdapterConfiguration `
            | Where-Object {$_.IPEnabled} `
            | Select-Object -ExpandProperty DefaultIPGateway

if (-not $Gateway) {
    Write-Warning 'No IP enabled adapter with a default gateway found. Exiting.'
    exit
}

# --------------------------------------------------------------------------- #
function Show-Menu {
    param([string]$gateway)

    Write-Host "Current default gateway(s):"
    foreach ($g in $gateway) { Write-Host "- $g" }

    Write-Host "Choose an action:"
    Write-Host " 1 - Disable the current default route (replace with a custom one)"
    Write-Host " 2 - Restore the original default route from file"
    Write-Host " 3 - Persist this change at logon via a scheduled task"
    Write-Host " 4 - Show all unique gateways in the routing table and their metric IDs"
    Write-Host " X - Exit"

    return Read-Host 'Enter your choice'
}

# --------------------------------------------------------------------------- #
$choice = Show-Menu $Gateway

    $choice = $choice.Trim()
    switch ($choice) {

        # --------------------------------------------------------------- #
        '1' {
            # Store the current gateway(s) for later restoration
            $Gateway | Out-File -Encoding UTF8 -FilePath $DataFile -Force

            # Remove any existing default route (0.0.0.0/0)
            Get-NetRoute -DestinationPrefix '0.0.0.0/0' |
                ForEach-Object { Remove-NetRoute -InputObject $_ }

            # Add a *new* default route that points to the first gateway
            # (You can change this IP if you want to block traffic.)
            $customNextHop = '192.168.13.13'   # <-- replace with your own

            Add-NetRoute `
                -DestinationPrefix '0.0.0.0/0' `
                -InterfaceAlias Ethernet `
                -NextHop $customNextHop `
                -PolicyStore ActiveStore

            Write-Host 'Default route replaced – traffic will now go to 192.168.13.13'
        }

        # --------------------------------------------------------------- #
        '2' {
            if (-not (Test-Path $DataFile)) {
                Write-Warning "No stored gateway file found at $DataFile."
                break
            }

            $originalGateways = Get-Content -Path $DataFile

            # Remove the custom route first
            Get-NetRoute -DestinationPrefix '0.0.0.0/0' |
                ForEach-Object { Remove-NetRoute -InputObject $_ }

            # Restore each original gateway
            foreach ($gw in $originalGateways) {
                Add-NetRoute `
                    -DestinationPrefix '0.0.0.0/0' `
                    -InterfaceAlias Ethernet `
                    -NextHop $gw `
                    -PolicyStore ActiveStore
            }

            Write-Host "Restored the original gateway(s): $( $originalGateways -join ', ')"
        }

        # --------------------------------------------------------------- #
        '3' {
            $date     = Get-Date -Format 'yyyy_MM_dd'
            $logFile  = Join-Path $LogDir "$date.txt"

            Add-Content -Path $logFile `
                -Value "Gateway(s) blocked on $(Get-Date): $( $Gateway -join ',' )"

            # Create a scheduled task that runs *this* script at log‑on
            $action   = New-ScheduledTaskAction -Execute 'powershell.exe' `
                                                -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`""
            $trigger  = New-ScheduledTaskTrigger -AtLogOn

            Register-ScheduledTask `
                -Action $action `
                -Trigger $trigger `
                -TaskName 'Block-Gateway' `
                -Description 'Replace the default gateway at every log‑on' `
                -User (whoami) `
                -RunLevel Highest `
                -Force

            Write-Host "Scheduled task created. The script will run at each log‑on."
        }
 # --------------------------------------------------------------- #
      '4' {
            Write-Host "Unique gateways currently in the routing table:`n"

            # Grab all default routes (0.0.0.0/0).  The result set may contain
            # multiple entries – for example if you have several NICs.
            $routes = Get-NetRoute -DestinationPrefix '0.0.0.0/0' |
                      Select-Object -Property NextHop, Metric

            if ($routes.Count -eq 0) {
                Write-Warning "No default routes found."
                break
            }

            # Group by gateway (NextHop) so that each unique gateway appears once.
            $unique = $routes | Group-Object -Property NextHop |
                      Sort-Object -Property Name

            foreach ($g in $unique) {
                $gatewayIP   = $g.Name
                $metrics     = ($g.Group | Select-Object -ExpandProperty Metric) -join ', '
                Write-Host "  Gateway : $gatewayIP"
                Write-Host "  Metrics : $metrics"
            }
        }

        # --------------------------------------------------------------- #
        Default {
            Write-Warning "Unrecognised choice: $choice"
        }
    }

    # Show menu again
    $choice = Show-Menu $Gateway
Write-Host "Exiting the script. "-ForegroundColor Green
Start-Sleep -Seconds 2
# SIG # Begin signature block
# MIIFuwYJKoZIhvcNAQcCoIIFrDCCBagCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUbSM4t9L/GGphXuKfFdCguw15
# RlegggM8MIIDODCCAiCgAwIBAgIQVc1z35+8BY5JQpb70tzgIDANBgkqhkiG9w0B
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
# BAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUQ8sPQONm+ThFaacYGldhL9JXOdowDQYJ
# KoZIhvcNAQEBBQAEggEAko8SdOVyKMbbCTaoqB9DJagVF+Goai6fRMyXNQ2NjDqf
# fdox2OUW+KnOF885hiKtLt//RJWXnqX+BcSnliaeDbUFzv/sjAJAavEjnRHqUf8u
# a+BjpnN4Pgc9zqZApcRWS3N+zx//NkK9GO4AE5NCAnnXvsdxtjtAbXz/2MTHePpZ
# HPw+qX81H2W1nPWY5qXKXoUkgnTKHFEuIEbadVEzEHKUZHEDpU3BaC0lVmGnAUmh
# zTSu7ZluLvIqlgBSCJUZvREFvsAPB37CvFo0ursI+MFlJsBcyHCpL1+flKvfxrwI
# iYQfCdSQIYA26u7RR1+7sHj0F37DK7lB0+ajcXDB4Q==
# SIG # End signature block
