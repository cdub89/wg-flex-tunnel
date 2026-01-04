# Network Stack Reset Utility for WireGuard ICS
# Run as Administrator
# WARNING: System reboot required after running this script

# 1. Stop the ICS and related services
Stop-Service -Name "SharedAccess" -Force -ErrorAction SilentlyContinue
Stop-Service -Name "BFE" -Force -ErrorAction SilentlyContinue

# 2. Reset the Network Stack
netsh winsock reset
netsh int ip reset
netsh interface ipv4 reset
netsh interface ipv6 reset

# 3. Restart the Base Filtering Engine (Essential for WireGuard)
Start-Service -Name "BFE"

Write-Host "Network Stack Reset Complete. Please REBOOT your computer now." -ForegroundColor Cyan

Write-Host "Pausing 15 seconds to review results.."
Start-Sleep -Seconds 15

# SIG # Begin signature block
# MIIFTAYJKoZIhvcNAQcCoIIFPTCCBTkCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUXWKdVxaKojgRkK4xmY8W4lNA
# otKgggLyMIIC7jCCAdagAwIBAgIQbdDcjU+gYpxMq6sLh6MSNjANBgkqhkiG9w0B
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
# 9w0BCQQxFgQUvqaStv8jCpOSMZRc+m7/vCRs9v8wDQYJKoZIhvcNAQEBBQAEggEA
# HudvpXFwegi4kijwETeM0EO88GARfjS3mJ0gY9ke/ElefYoiOuiekhXCftpqhs4Q
# LcXQRylEzLStKh3Ri6v8rDYFLjU2dWi3Iz9ifrpx7BdiBew0Z4iZsPrpVvw139qE
# X01kE2Ls3tgNf7yIDJi85ovWcmqLKfqr9cK0VOUFl2Fwl3EthbjJw04lhJ3yXUaX
# 96Q1f4Y+vY6V8gKgED06SLONqteHFpBBbChinboIMq8tzZG1C8WdRza//1vf3OMt
# WkMoAMw1FjfBgfXa36IVuXQeaQIUJiU9I2FlHWDx/BI/rp/QXcpZLHJ5ewwA5LXA
# Iye6AgW7O6HKHEjFln7ekQ==
# SIG # End signature block
