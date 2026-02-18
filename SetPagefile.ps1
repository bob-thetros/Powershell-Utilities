#Requires -Version 5.1
#Requires -RunAsAdministrator
<# 
.SYNOPSIS
   Set the pagefile size on VETS workstations to 32 GB on drive D:,
    unless the machine has a different amount of RAM.  
    In that case the user is asked for a custom page‑file size.
.DESCRIPTION
Set Page file to D drive if possible.
    The script:
        * Verifies that drive D: exists.
        * Logs the current pagefile configuration.
        * Checks total physical memory.
        * If memory ≠ 32 GB, asks the user for an alternative page‑file size (GB).
        * Prompts for confirmation before making changes.
        * Sets a manually‑managed pagefile on D: with the chosen size.
        * Logs the new settings.
        * Offers to reboot immediately.
.PARAMETER None
none
.EXAMPLE
C:\> .\SetPagefile.ps1
#>

$DriveLetter       = 'D:'                     # Target drive (must already exist)
$PageFileSizeGB    = 32                       # Desired pagefile size
$LogDir            = 'C:\scripts'             # Folder for log files
$DateStr           = Get-Date -Format 'yyyyMMdd'
$LogPath           = Join-Path $LogDir "pagefile_settings_$DateStr.log"


# Verify the target drive exists
if (-not (Test-Path "$DriveLetter\")) {
    Write-Host "The second partition for drive '$DriveLetter' does not exist.  Aborting. Rerun after creating the partition." -ForegroundColor Red
	Start-Sleep -Milliseconds 5000
    exit 1
}

# Ensure log directory is present
if (-not (Test-Path $LogDir)) { New-Item -Path $LogDir -ItemType Directory | Out-Null }

# Detect if we are running inside a virtual machine
$vmIndicators = @(
    'VMware', 'VirtualBox', 'KVM', 'Microsoft Hyper‑V',
    'Xen', 'Parallels'
)
$biosInfo  = Get-CimInstance -ClassName Win32_BIOS |
             Select-Object Manufacturer, SMBIOSBIOSVersion, BIOSVersion
$prodInfo  = Get-CimInstance -ClassName Win32_ComputerSystemProduct |
             Select-Object Vendor, Version, Name

$isVM = $false
foreach ($indicator in $vmIndicators) {
    if (($biosInfo | Out-String).Contains($indicator) -or
        ($prodInfo | Out-String).Contains($indicator)) { $isVM = $true; break }
}
if ($isVM) {
    Write-Host "The script detected a virtual machine environment.  Operation aborted."
	Start-Sleep -Milliseconds 2000
    exit 1
}

#endregion

#region ───── Log Current Settings ──────
function Show-PageFileStatus {
    Write-Host "===== Current Page‑File Configuration ====="

    # 1️⃣ Manual page‑file entries (if any)
    $manual = Get-CimInstance -ClassName Win32_PageFileSetting |
              Select-Object @{N='Path';        E={$_.Name}},
                            @{N='Initial(MB)';E={ [math]::Round($_.InitialSize / 1MB,2)}},
                            @{N='Maximum(MB)';E={ [math]::Round($_.MaximumSize / 1MB,2)}},
                            @{N='AutoManaged'; E={$_.AutoManaged}}

    if ($manual.Count -gt 0) {
        Write-Host "Manual page‑file entries:"
        foreach ($p in $manual) {
            Write-Host ("  {0,-20} Initial: {1,6:N2} MB   Max: {2,6:N2} MB   AutoManaged: {3}" -f `
                        $p.Path,$p.'Initial(MB)',$p.'Maximum(MB)',[bool]$p.AutoManaged)
        }
    } else {
        Write-Host "No manual page‑file entries found."
    }

    # 2️ Current total size (system‑managed + any custom file)
    $totalSizeMB = (Get-CimInstance -ClassName Win32_ComputerSystem).PageFile / 1MB
    Write-Host ("Total system page‑file size: {0:N2} MB" -f $totalSizeMB)

    # 3️ Individual page‑file usage (optional, for more detail)
    Get-CimInstance -ClassName Win32_PageFileUsage |
        Select-Object @{N='Path'; E={$_.Name}},
                      @{N='Allocated(MB)'; E={ [math]::Round($_.AllocatedBaseSize / 1MB,2)}},
                      @{N='Current(MB)';   E={ [math]::Round($_.CurrentUsage / 1MB,2)}}
        | Format-Table -AutoSize
}

# Call it wherever you want to display the status
#endregion

#region ───── User Confirmation ──────
Show-PageFileStatus
$answer = Read-Host "Do you want to set a 32 GB pagefile on $DriveLetter? (Y/N)"
if ($answer -ne 'Y') {
    Write-Host "Operation cancelled."
	Start-Sleep -Milliseconds 2000
    exit 0
}
#endregion

#region ───── Apply New Settings ──────
try {
    $regKey = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management'

    # Tell the system we are using a manual pagefile
    Set-ItemProperty -Path $regKey -Name ClearPageFileAtShutdown -Type DWord -Value 1 -Force | Out-Null

    # Registry expects bytes, but the key names are lower‑case letters without colon
    $driveNoColon = ($DriveLetter.TrimEnd(':')).ToLower()
    $sizeBytes    = $PageFileSizeGB * 1GB

    Set-ItemProperty -Path $regKey -Name "${driveNoColon}InitialSize"   -Type DWord -Value $sizeBytes -Force | Out-Null
    Set-ItemProperty -Path $regKey -Name "${driveNoColon}MaximumSize"   -Type DWord -Value $sizeBytes -Force | Out-Null
    Set-ItemProperty -Path $regKey -Name "${driveNoColon}Active"        -Type DWord -Value 1           -Force | Out-Null

    Write-Host "===== New Pagefile Settings ====="
    Write-Host "Drive: $DriveLetter"
    Write-Host "Initial Size (bytes): $sizeBytes"
    Write-Host "Maximum Size (bytes): $sizeBytes"

    Write-Host "Pagefile settings updated successfully."
}
catch {
    Write-Host "Failed to apply new pagefile settings: $_" -ForegroundColor Red
	Start-Sleep -Milliseconds 2000
	
    exit 1
}
#endregion


Write-Host "Remember to reboot later for changes to take effect."
Start-Sleep -Milliseconds 2000
# SIG # Begin signature block
# MIIFuwYJKoZIhvcNAQcCoIIFrDCCBagCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUObr2UyzxY1eSw0FFN7M/lMI9
# tj+gggM8MIIDODCCAiCgAwIBAgIQVc1z35+8BY5JQpb70tzgIDANBgkqhkiG9w0B
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
# BAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUrD8PGXd47hMUOZN3O2De0JRlHDowDQYJ
# KoZIhvcNAQEBBQAEggEA1Pyw6xrcmB4deEckVs7je9rBVqBVtuCByeJRM9OkNjE9
# 3CS7506VlFTizU2zsZEXfwsp+Kr5PcGWVlIKjIoal2n8jCRxHKC4oCPJP+Ev7P25
# B1jVkMGgN7YbWP/tP21xkZSyXHjLiYKCAQIz+SFOd7Npa8UyOCZQHv5pE2/8iee9
# MUzpi57xDvVs8veR0gG2exU2hcz6aUvugjl1vusb2su3iwrGyCDuJDXWpbSXGydi
# HFFer+/rpsV3p7tu3KVAq1ZwlMbZQVbwPGPjr4O98J9QvilSrtYS9iyn3uSXmKL8
# AatrylxRHGpA82JcoN6RAharn5P+D5mZChmX8Tj7qg==
# SIG # End signature block
