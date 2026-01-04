Write-Host "--- Windows 11 VPN & ICS Health Check ---" -ForegroundColor Cyan

# Check Registry Keys
# Note: In this setup SharedAccess should be 0 (disabled persistence)
$regPaths = @(
    "HKLM:\SOFTWARE\WireGuard|DangerousScriptExecution|1",
    "HKLM:\SYSTEM\CurrentControlSet\Services\PolicyAgent|AssumeUDPEncapsulationContextOnSendRule|2",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\SharedAccess|EnableRebootPersistConnection|0"
)

Write-Host "`n[Registry Settings]"
foreach ($item in $regPaths) {
    $path, $val, $expected = $item.Split('|')
    $current = (Get-ItemProperty -Path $path -ErrorAction SilentlyContinue).$val
    if ($current -eq $expected) {
        Write-Host "OK: $val is $current" -ForegroundColor Green
    } else {
        Write-Host "FAIL: $val is $current (Expected $expected)" -ForegroundColor Red
    }
}

# 2. Check Essential Services
Write-Host "`n[Service Status]"
$services = @{ "BFE"="Base Filtering Engine"; "SharedAccess"="Internet Connection Sharing"; "wireguard"="WireGuard Service" }
foreach ($s in $services.Keys) {
    $status = Get-Service -Name $s -ErrorAction SilentlyContinue
    if ($status.Status -eq 'Running') {
        Write-Host "OK: $($services[$s]) is Running" -ForegroundColor Green
    } else {
        Write-Host "FAIL: $($services[$s]) is $($status.Status)" -ForegroundColor Red
    }
}

# 3. Check Network Sharing (ICS) Active State
Write-Host "`n[ICS Active State]"
$m = New-Object -ComObject HNetCfg.HNetShare
$isSharing = $false
foreach ($c in $m.EnumEveryConnection) {
    if ($m.INetSharingConfigurationForINetConnection($c).SharingEnabled) { $isSharing = $true }
}

if ($isSharing) {
    Write-Host "OK: ICS Sharing is currently active on at least one adapter." -ForegroundColor Green
} else {
    Write-Host "NOTICE: ICS is not currently active (Check if WireGuard is connected)." -ForegroundColor Yellow
}

Write-Host "Pausing 5 seconds to review results..."
Start-Sleep -Seconds 5

# SIG # Begin signature block
# MIIFTAYJKoZIhvcNAQcCoIIFPTCCBTkCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUzLDXW2cC76R8SogyxLB+fgKR
# ZDCgggLyMIIC7jCCAdagAwIBAgIQbdDcjU+gYpxMq6sLh6MSNjANBgkqhkiG9w0B
# AQsFADAPMQ0wCwYDVQQDDAR3eDd2MB4XDTI2MDEwNDAzNDMzOFoXDTI3MDEwNDA0
# MDMzOFowDzENMAsGA1UEAwwEd3g3djCCASIwDQYJKoZIhvcNAQEBBQADggEPADCC
# AQoCggEBAKjRvf0yVPhyYt/DtnbcJbUCwU0JkQwrlrLsUjj5ANNh0RDn+MMvJP63
# WgqzQQDt9vdgJZGgmyySg1RllLcrQon/Fg/EZn4XD8QbDyuJjCD24/pCrWKAw7Uj
# 1G3SRttISpr0ACYArAd9iKPqdPV244obIxBmi2gGYEd9PlI4xTuPEDoi21YxDWRg
# kkDjIjL8B9smG8gSSIn1Jnt88jcMgvBdQyv5a60IAUSW3yIjNA+UBHO6LWzYX2Fy
# +/exF2W7FyKYJCq4hU543ejkr04TtNTxqDWD7uBpiR8YENLyZzs0QI280PR/Gkli
# ieXdLnUA1M74UGQKbKDXjE5SKFEaajkCAwEAAaNGMEQwDgYDVR0PAQH/BAQDAgeA
# MBMGA1UdJQQMMAoGCCsGAQUFBwMDMB0GA1UdDgQWBBRCKEJcN2ZazC5GRR/nb1xs
# Ht0XlDANBgkqhkiG9w0BAQsFAAOCAQEAHmlS4YtVNNStHJIlcYB8U8E505wsDUom
# 0kHd2kK1zQxMJ4G9dLutPWqmZZlnYYnQErr3yz4AiIs8on12sHVURa//ze8BePKX
# SIP7X1yw0uQxwYEceSjV+hCQF9FbaY918WCtIxd7AFZAkgWFY8TcqaIio1l30kTO
# jaGNakpPv/2hXqgdKJsxl5WGle6fH5eJeK414wgQoXgKCvn9GdZ5xHF/RFRjfx/y
# 6jJgd8Z1zl3BFmLij72cMyp8wIcuyymIMjMq3oekWE+yP3VtaFKb6AN/JASSY0wC
# yIoShxDVh6s4Zw9d5nS6b+/SmtlgQnfhylVNjN+TfMS9Iqu9jOG6tzGCAcQwggHA
# AgEBMCMwDzENMAsGA1UEAwwEd3g3dgIQbdDcjU+gYpxMq6sLh6MSNjAJBgUrDgMC
# GgUAoHgwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYK
# KwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG
# 9w0BCQQxFgQUPDJ/uyBDenquwZpxq0xL2c4A3lwwDQYJKoZIhvcNAQEBBQAEggEA
# ZNwn9wFa6/4wAkDFjtRY1+qMuQl7pCrTwXVhZ+rk+JBnC+t7Kikgz09ykzzlemeI
# NY9PSxNpk6v2vyCqTOh2Wiyb/GTJCbSt3Q3oxCpOiSiEzm1ZvCyTwEytVVq+B+Y7
# yDrd2afRktKnJSn+iFu2Cg7vSUrU2ldBEhXL2TOKiDwjsTp/xj/pmsVwkeU6SMtp
# SQ5dGHHqR+0AMzEQKFwKXg94+g7nMaQY1Lyb9j3E5R5Z/404lXyRa660bnjPqEQP
# /NheXSgV5r3gU3W8+28tqrRUmlk2WWU4b17kIbqVoPy49IpoOqfQcp7ehAVuRg7m
# IAvpZyAKiYzcidSaTvhBsw==
# SIG # End signature block
