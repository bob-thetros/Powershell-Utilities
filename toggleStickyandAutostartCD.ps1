<#
.SYNOPSIS
    Toggles Sticky Keys and AutoRun settings via the registry and logs actions to the Application event log.
.DESCRIPTION
    This script modifies the Sticky Keys and AutoRun settings in the Windows registry. It allows the user to enable or disable these features interactively. The changes are logged to the Application event log under the source "StickyAndAutoRunToggle".
.PARAMETER 
None
.EXAMPLE
C:\> .\toggleStickyandAutostartCD.ps1
#>
function Modify-AutoRunSetting {
    $registryPath = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"
    $settingName = "NoDriveTypeAutoRun"

    try {
        # Get the current value of the setting
        $currentValue = (Get-ItemProperty -Path $registryPath -Name $settingName).$settingName

        Write-Host "Current AutoRun setting (255=Disabled and 149=enabled): $currentValue"

        # Prompt the user for action
        $action = Read-Host "Enter 'd' to disable, 'e' to enable, or leave blank to skip AutoRun CD modification."

        if ($action -eq "d") {
            # Disable the setting (set to 255)
            $newValue = 255
            Set-ItemProperty -Path $registryPath -Name $settingName -Value $newValue -Type DWord
            Write-Host "AutoRun disabled. Setting value to: $newValue"

        } elseif ($action -eq "e") {
            # Enable the setting (set to 149)
            $newValue = 149
            Set-ItemProperty -Path $registryPath -Name $settingName -Value $newValue -Type DWord
            Write-Host "AutoRun enabled. Setting value to: $newValue"

        } else {
            Write-Host "Skipping AutoRun modification."
        }


    } catch {
        Write-Error "An error occurred during AutoRun modification: $($_.Exception.Message)"
    }
}

# Function to modify the Sticky Keys registry setting
function Modify-StickyKeysSetting {
    $registryPath = "HKCU:\Control Panel\Accessibility\StickyKeys"
    $settingName = "Flags"

    try {
        # Get the current value of the setting and display it
        $currentValue = (Get-ItemProperty -Path $registryPath -Name $settingName).$settingName
        Write-Host "Current Sticky Keys Flags value(506=disabled 510=enabled): $currentValue"

        # Prompt the user for action regarding Sticky Keys
        $stickyAction = Read-Host "Enter 'd' to disable, 'e' to enable Sticky Keys, or leave blank to skip."

        if ($stickyAction -eq "d") {
            # Disable Sticky Keys (set Flags to 506)
            $newValue = 506
            Set-ItemProperty -Path $registryPath -Name $settingName -Value $newValue -Type DWord
            Write-Host "Sticky Keys disabled. Setting value to: $newValue"

        } elseif ($stickyAction -eq "e") {
            # Enable the setting (set to 510)
            $newValue = 510
            Set-ItemProperty -Path $registryPath -Name $settingName -Value $newValue -Type DWord
            Write-Host "Sticky Keys enabled. Setting value to: $newValue"
        } else {
            Write-Host "Skipping Sticky Keys modification."
        }

    } catch {
        Write-Error "An error occurred during Sticky Keys modification: $($_.Exception.Message)"
    }
}


# Call the functions to modify the settings
Modify-AutoRunSetting
Modify-StickyKeysSetting

Try {
    Set-Service -Name SysMain -StartupType Disabled
    Write-Host "SysMain -Siemens app startup type set to Disabled." -ForegroundColor Green
} Catch {
    Write-Warning "Failed to disable SysMain startup: $($_.Exception.Message)"
}

Write-Host "Adjustments completed." -ForegroundColor Cyan
  Start-Sleep -Milliseconds 2000

# SIG # Begin signature block
# MIIFuwYJKoZIhvcNAQcCoIIFrDCCBagCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU5iDX7euVcYeleaiAvoQzzngj
# BQ6gggM8MIIDODCCAiCgAwIBAgIQVc1z35+8BY5JQpb70tzgIDANBgkqhkiG9w0B
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
# BAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUIv41G84TyNLnXntLkzQkGJJawwYwDQYJ
# KoZIhvcNAQEBBQAEggEASYINtvnxKDtjt/sMmns2pyLvWCsM7/vEEUk+b7PhQTcI
# Vfz4Pdp9mawIVn5DknbXmiH9bZ5hT6AK2F0bhBhwFRw4yziPYHpm9WEfDfezMDn2
# 6WNtlSsYIR2Yth1QJeJQspqmsud6EeCYMiy06zINbjfq3/OKuaF816+hZZZwPpvd
# ZtkFuv7jDfB1z0faJCdFUiz/58yJbcRaxP4FOLFIU+blM78MzT1G4kK2g2YArF5n
# +i0715jfCWyLB78LgxZrhjbtl46fPXyNvg8kpy6ASXZwtVXxxThnsUV+ZXLXgDzC
# zUDYrxnJlJGOdIsaWcyiHZZQhStfdPVJDtEkBZPuOg==
# SIG # End signature block
