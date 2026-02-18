#Requires -Version 5.1
#Requires -RunAsAdministrator
<# 
.SYNOPSIS
    Reset Windows Update services and clear its cache, then toggle Automatic Updates.
.DESCRIPTION
    Stops wuauserv, CryptSvc and BITS; backs up the catroot2 / SoftwareDistribution folders,
    flushes DNS, removes any leftover BITS queue files, re‑registers all WinUpdate DLLs,
    restarts the services (including wuauserv), logs everything, and finally prompts the
    user to enable or disable Automatic Updates.
.PARAMETER None
.EXAMPLE
C:\> .\toggleWindowsUpdates.ps1
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param ()

#region ── Logging helpers ───────────────────────────────────────────────

$LogBase   = 'C:\scripts\reports'
$DateStamp = Get-Date -Format 'yyyyMMdd-HHmmss'

$installerName = 'WindowsUpdates'          # <-- change if needed
$LogFile   = Join-Path $LogBase "$($env:COMPUTERNAME)-$($installerName)-$DateStamp.txt"

function Write-Log {
    param(
        [Parameter(Mandatory)][string]$Message,
        [ValidateSet('INFO','WARN','ERROR')][string]$Level='INFO'
    )
    $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    Add-Content -Path $LogFile -Value "$ts [$Level] $Message"
}

Write-Host "=== Windows Update Reset Utility ===" -ForegroundColor Cyan
Write-Host "Logging to : $LogFile`n"

#endregion

#region ---- Helper Functions ---------------------------------------------------

function Stop-ServiceSafe {
    param([string[]]$Name)
    foreach ($svc in $Name) {
        if (($s = Get-Service -Name $svc -ErrorAction SilentlyContinue).Status -ne 'Stopped') {
            Write-Log "Stopping service: $svc"
            if ($PSCmdlet.ShouldProcess($svc, 'Stop')) { Stop-Service -Name $svc -Force -ErrorAction Stop }
        } else { Write-Log "$svc already stopped" }
    }
}

function Start-ServiceSafe {
    param([string[]]$Name)
    foreach ($svc in $Name) {
        if (($s = Get-Service -Name $svc -ErrorAction SilentlyContinue).Status -ne 'Running') {
            Write-Log "Starting service: $svc"
            if ($PSCmdlet.ShouldProcess($svc, 'Start')) { Start-Service -Name $svc -ErrorAction Stop }
        } else { Write-Log "$svc already running" }
    }
}

#endregion

#region ---- 1. Stop Services ---------------------------------------------------

Stop-ServiceSafe @('wuauserv','CryptSvc','BITS')

#endregion

#region ---- 2. Backup & rename critical folders -------------------------------

$folders = @{
    Catroot2          = Join-Path $env:SystemRoot 'System32\catroot2'
    SoftwareDistribution = Join-Path $env:SystemRoot 'SoftwareDistribution'
    DownloaderQueue   = Join-Path $Env:ProgramData 'Microsoft\Network\Downloader'
}

foreach ($name in $folders.Keys) {
    $path = $folders[$name]
    if (Test-Path $path) {
        $bak = "$path.bak$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        Write-Log "Backing up $name -> $bak"
        Rename-Item -LiteralPath $path -NewName $bak -Force
    }
}

#endregion

#region ---- 3. Flush DNS & delete BITS queue files -----------------------------

Write-Log "Flushing DNS..."
ipconfig /flushdns | Out-Null

$bitsFolder = Join-Path $Env:ProgramData 'Microsoft\Network\Downloader'
if (Test-Path -LiteralPath $bitsFolder) {
    Write-Log "Removing BITS queue files"
    Get-ChildItem -LiteralPath $bitsFolder -Filter '*.dat' -Force | Remove-Item -Force
}

#endregion

#region ---- 4. Rename pending.xml & WindowsUpdate.log ------------------------

$special = @(
    "$env:SystemRoot\winsxs\pending.xml",
    "$env:SystemRoot\winsxs\pending.xml.bak",
    "$env:SystemRoot\WindowsUpdate.log",
    "$env.SystemRoot\WindowsUpdate.log.bak"
)

foreach ($file in $special) {
    if (Test-Path -LiteralPath $file) {
        $bak = "${file}.bak$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        Write-Log "Renaming $file -> $bak"
        Rename-Item -LiteralPath $file -NewName $bak -Force
    }
}

#endregion

#region ---- 5. Restore default ACLs on services ------------------

$svcList = @('BITS','wuauserv')
foreach ($svc in $svcList) {
    Write-Log "Restoring ACL for $svc"
    sc.exe sdset $svc "D:(A;;CCLCSWRPWPDTLOCRRC;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCLCSWLOCRRC;;;AU)(A;;CCLCSWRPWPDTLOCRRC;;;PU)" | Out-Null
}

#endregion

#region ---- 6. Re‑register DLLs ---------------------------------------------

$dllList = @(
    'atl.dll','urlmon.dll','mshtml.dll','shdocvw.dll',
    'browseui.dll','jscript.dll','vbscript.dll','scrrun.dll',
    'msxml.dll','msxml3.dll','msxml6.dll','actxprxy.dll',
    'softpub.dll','wintrust.dll','dssenh.dll','rsaenh.dll',
    'gpkcsp.dll','sccbase.dll','slbcsp.dll','cryptdlg.dll',
    'oleaut32.dll','ole32.dll','shell32.dll','initpki.dll',
    'wuapi.dll','wuaueng.dll','wuaueng1.dll','wuchlti.dll',
    'wups.dll','wups2.dll','wuweb.dll','qmgr.dll','qmgrprxy.dll',
    'wucltux.dll','muweb.dll','wuwebv.dll','wudriver.dll'
)

foreach ($dll in $dllList) {
    Write-Log "Registering $dll"
    regsvr32.exe /s $dll | Out-Null
}

#endregion

#region ---- 7. Restart services ----------------------------------------------

Write-Log "Starting BITS, CryptSvc and wuauserv..."
Start-ServiceSafe @('BITS','CryptSvc','wuauserv')

Write-Log "=== Completed. Windows Update cache has been cleared. ==="

#endregion

#region ---- 8. Toggle Automatic Updates -------------------------------------

$regPath = 'HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate\AU'
$keyName = 'ConfigureAutomaticUpdates'

# Ensure the key exists
if (-not (Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }

# Get current value (default 1 if not set)
$currentVal = (Get-ItemProperty -Path $regPath -Name $keyName -ErrorAction SilentlyContinue).$keyName
if ($null -eq $currentVal) { $currentVal = 1 }   # default: enabled

Write-Host "`nCurrent Automatic Updates state: $(if($currentVal -eq 2){'Disabled'}else{'Enabled'})"
$choice = Read-Host "Do you want to Disable (Y) or Enable (N) Windows Automatic Updates?"

switch ($choice.ToUpper()) {
    'Y' {   # user wants to disable
        if ($currentVal -eq 2) {
            Write-Log "Automatic Updates already disabled."
            Write-Host "No change needed – Automatic Updates are already disabled." -ForegroundColor Yellow
        } else {
            try {
                Set-ItemProperty -Path $regPath -Name $keyName -Type DWord -Value 2 -Force
                Write-Log "Automatic Updates disabled (ConfigureAutomaticUpdates=2)"
                Write-Host "Automatic Updates have been **disabled**." -ForegroundColor Green
            } catch { Write-Log "ERROR setting registry: $_" }
        }
    }
    'N' {   # user wants to enable
        if ($currentVal -eq 1) {
            Write-Log "Automatic Updates already enabled."
            Write-Host "No change needed – Automatic Updates are already enabled." -ForegroundColor Yellow
        } else {
            try {
                Set-ItemProperty -Path $regPath -Name $keyName -Type DWord -Value 1 -Force
                Write-Log "Automatic Updates enabled (ConfigureAutomaticUpdates=1)"
                Write-Host "Automatic Updates have been **enabled**." -ForegroundColor Green
            } catch { Write-Log "ERROR setting registry: $_" }
        }
    }
    default {
        Write-Host "Invalid input. No action taken." -ForegroundColor Red
    }
}

#endregion

Write-Host "`nAll done. Check the log at $LogFile" -ForegroundColor Green

# SIG # Begin signature block
# MIIFuwYJKoZIhvcNAQcCoIIFrDCCBagCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUOCyPA8OG6miAgZLfEGDVx9hL
# 9I2gggM8MIIDODCCAiCgAwIBAgIQVc1z35+8BY5JQpb70tzgIDANBgkqhkiG9w0B
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
# BAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUqvYidrKuojwbERminONuqMJ1/uwwDQYJ
# KoZIhvcNAQEBBQAEggEAxnYZkc7RksSjwYD25v4sDwW0ToPO1r1+jLrlpCPEXfu8
# BmtGjdLusRq0mcNiragAiw4IORD2B6JZgBmEDnU5JY5cFd2xttrODUCdOOuIU1rZ
# axO6HDr5Jt4s8ZbnkuUmSSGMFV7/pd4BnsiRXXUNzPHiXbk4XVRtbeYId2bolyjE
# q+bjrexlvTQd7wtayA5niYWBXN0CwQPawbEtNZJBu3rTSvYF6cBDgAdjfg3dbr6c
# rJFF2C1Cs3mUPZjW40v2sqrzpRtizWxAX3biJ4KIS2i8XEsL/3oAsZXJqSEye9WV
# 0T4lt9f6Bc3y8GKxq2fN+6VFs2xrTSyeefi9adnW6Q==
# SIG # End signature block
