<#
.SYNOPSIS
Windows Defender Report Performance Gather performance data
.DESCRIPTION
Windows Defender Report Performance Gather performance data
.PARAMETER none
none
.EXAMPLE
C:\> .\DefenderReportPerformance.ps1
Creates a app-list.csv and compares to the ref.csv you specify. Otherwise compares to c:\scripts\app-reference.csv
#>
$computerName = $env:COMPUTERNAME

if ($computerName.StartsWith("HAD")) {
  Write-Host "Aborting script since computer name starts with HAD.  We use Trend AV."
  exit
}

# Rest of script logic goes here
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Get-MpComputerStatus
set-mppreference -AllowDatagramProcessingOnWinServer False -DisableGradualRelease 1 -DisableInboundConnectionFiltering 1 -DisableRealtimeMonitoring 1 -EnableLowCpuPriority 1 -MAPSReporting 0 -RealTimeScanDirection 2 -RemediationScheduleDay 8 -ScanAvgCPULoadFactor 5 -ScanOnlyIfIdleEnabled   -ScanScheduleDay 8 -SubmitSamplesConsent -DisableRemovableDriveScanning 0
# ref https://learn.microsoft.com/en-us/powershell/module/defender/set-mppreference?view=windowsserver2022-ps
New-MpPerformanceRecording -RecordTo "$scriptDir/recording.etl"

$report = Get-MpPerformanceReport -Path .\recording.etl -TopFiles 10 -TopExtensions 10 -TopProcesses 10 -TopScans 10
$report | Export-Csv -Path .\report.csv -NoTypeInformation
Get-MpPerformanceReport -Path .\recording.etl -TopFiles 10 -TopExtensions 10 -TopProcesses 10 -TopScans 10 
# SIG # Begin signature block
# MIIFuwYJKoZIhvcNAQcCoIIFrDCCBagCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUXCVa4+EROMNjN65iu8hAKq4x
# jB6gggM8MIIDODCCAiCgAwIBAgIQVc1z35+8BY5JQpb70tzgIDANBgkqhkiG9w0B
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
# BAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQU6SrxDGYt+iAmr7Zul0R9jJLD4GcwDQYJ
# KoZIhvcNAQEBBQAEggEA0b3HBQPiy5hqVlpwHFujRuH9ASGlGS/hygPo2SHJsSEX
# QwuvvHF6tNIXCrfDjx+WLthHYeza10SQE/IH9WpqFvdW1PYaWOwE4BnhFNB/yrCS
# HP6/wnBCwzJgXSIgjOrOuSfQVcpwhsLoM+RKNDcz3KHNn6AV7NEhk9rahrZ7clGt
# B/MCBmukuyNIP5uN/m2ZYdtsriIVz4eYQRrdvlhuD9qNS5GOe8FzW0wwemqIlcuN
# BP8ZZXD5aqyGoXcxMo6glTkSxwql7eRiyktmf1DOGiL1+F0VgSTMJ4DlpLf+AEtt
# CcE+pYjvTX19gp8ns0djqZBouYOdSV1YkauL+Y2mhQ==
# SIG # End signature block
