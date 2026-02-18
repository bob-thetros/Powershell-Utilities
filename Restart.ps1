
<#
.SYNOPSIS
Reboot PC
.DESCRIPTION
Reboot PC. Confirms STARS is stopped first.
.PARAMETER None
none
.EXAMPLE
C:\> .\RebootPC.ps1
#>
#shutdown /r /fw 
# Check that the STARS services are running
if ((Get-WmiObject -Class Win32_Service -Filter "Name='StarsExecutionEnvironment'" | select-object -expandproperty "State") -eq "Running")
{
    [System.Windows.Forms.MessageBox]::Show("Please stop the STARS services and try again.Program will now exit." , "STARS Results Bulk Export Tool" , 0)
    $yn = Read-Host "To Abort enter A.  If the system is unresponsive for several minutes after attempting to close STARS, Press Y to confirm you may loose active test data."
    If ($yn -eq "A"){exit(0)}
    If ($yn -eq "Y"){
        Write-Host "Please create a trouble package after the system reboot so that we may determine the cause."
        Shutdown /r /f /d P:4:5 /c "Scripted to reboot forced by user due to STARS not responding.."
    }
}
Shutdown /r /f /d P:0:0 /c "Scripted to reboot system by user script."
Restart-Computer -Timeout 10 -Delay 60
write-host "PC restarting in 60 seconds"
# SIG # Begin signature block
# MIIFuwYJKoZIhvcNAQcCoIIFrDCCBagCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQURyt6EzGUySO5uvX5WauApSDR
# HuagggM8MIIDODCCAiCgAwIBAgIQVc1z35+8BY5JQpb70tzgIDANBgkqhkiG9w0B
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
# BAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUTCOtjZsG013moFQXPuNlRcKYNB4wDQYJ
# KoZIhvcNAQEBBQAEggEAud9d5WtIua0sYL/FaMiVee9Z7I3hsJxMCBTZv4kUmzob
# mqjSJ6zKposcsmyjkEbHGdOKsPscGrvuCn5CSh/4vod8gbwRNYLlUIk+q6fgbLWJ
# Ui0xEaP2fmIIlHxw5PQHOlAT1HJz6uR2DK/uCvYN3yKw2B629PH5onOHkGrPEPEj
# 4Hu6jSci5V9jE116MfSHCGmKJS/4xfhxD6xj0vj2+aX0nE3bl6zN03GE1vppVv6M
# Ocs0V1rmuoUbI4klRdTbp703EVkECoBcX42bnqKPtf8kKYbpJhhHq0YOqvmHOYmx
# u7uDBZLiECDTEOFA6lJrAkszYwHnrMZYNBuyq0wuSw==
# SIG # End signature block
