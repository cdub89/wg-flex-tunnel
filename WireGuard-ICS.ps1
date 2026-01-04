param([string]$Action)

$publicAdapterName = "WG-Flex"       # Check ncpa.cpl for exact name
$privateAdapterName = "Morconi"      # Check ncpa.cpl for exact name
$logFile = "C:\Morconi\wg-flex-tunnel\wg_vpn_tunnel.log"

function Write-Log {
    param([string]$Message)
    $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$TimeStamp - $Message" | Out-File -FilePath $logFile -Append
}

$mNetSharing = New-Object -ComObject HNetCfg.HNetShare

try {
    if ($Action -eq "Enable") {

        Write-Log " "
        Write-Log "Starting WireGuard-ICS Post Up Process."
        Write-Log "Resetting $privateAdapterName to DHCP to prevent IP conflicts..."
        # Forces the sharing adapter to DHCP so ICS can manage the IP

        # Check BFE and related services system health
        $services = "BFE", "SharedAccess", "nsi", "NetSetupSvc"
        foreach ($s in $services) {
            $status = Get-Service $s -ErrorAction SilentlyContinue
            if ($status) {
                Write-Host "$($status.DisplayName): $($status.Status)" 
            } else {
                Write-Host "Service $s not found!" -ForegroundColor Red
            }
        }

        Get-NetIPAddress -InterfaceAlias $privateAdapterName -AddressFamily IPv4 | Remove-NetIPAddress -Confirm:$false -ErrorAction SilentlyContinue
        Set-NetIPInterface -InterfaceAlias $privateAdapterName -Dhcp Enabled -ErrorAction SilentlyContinue
    
        Write-Log "Waiting 10 seconds for network stack to settle..."
        Start-Sleep -Seconds 10

        Write-Log "Attempting to Enable ICS..."
        $publicConn = $null
        $privateConn = $null

        foreach ($conn in $mNetSharing.EnumEveryConnection) {
            $props = $mNetSharing.NetConnectionProps($conn)
            if ($props.Name -eq $publicAdapterName) { $publicConn = $mNetSharing.INetSharingConfigurationForINetConnection($conn) }
            if ($props.Name -eq $privateAdapterName) { $privateConn = $mNetSharing.INetSharingConfigurationForINetConnection($conn) }
        }

        if ($publicConn -and $privateConn) {
            $publicConn.EnableSharing(0)
            $privateConn.EnableSharing(1)
            Write-Log "SUCCESS: ICS enabled from $publicAdapterName to $privateAdapterName."
        } else {
            Write-Log "ERROR: Could not find adapters. Public Found: $($publicConn -ne $null), Private Found: $($privateConn -ne $null)"
        }

        Write-Log "COMPLETE: WireGuard-ICS Post Up Process Complete."

    } 
    elseif ($Action -eq "Disable") {
        Write-Log "Attempting to Disable ICS..."
        foreach ($conn in $mNetSharing.EnumEveryConnection) {
            $config = $mNetSharing.INetSharingConfigurationForINetConnection($conn)
            if ($config.SharingEnabled) {
                $config.DisableSharing()
                Write-Log "SUCCESS: ICS disabled."
            }
        }

        # Stop the ICS and related services as part of the disable process.
        Stop-Service -Name "SharedAccess" -Force -ErrorAction SilentlyContinue
        Write-Log "COMPLETE: WireGuard-ICS Post Down Process Complete."
    }
} catch {
    Write-Log "CRITICAL ERROR: $($_.Exception.Message)"
}
# SIG # Begin signature block
# MIIFTAYJKoZIhvcNAQcCoIIFPTCCBTkCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUYue4QNqDaaQEaOs+Jn/0tIcP
# i7ugggLyMIIC7jCCAdagAwIBAgIQbdDcjU+gYpxMq6sLh6MSNjANBgkqhkiG9w0B
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
# 9w0BCQQxFgQUc/AhdrFt6dWaJR0biWP3R7AWnMowDQYJKoZIhvcNAQEBBQAEggEA
# ltCkkLq+l8DcW4j+YThSjR2MgsQOc9MuPlhaviLruiQLg98MbkgovqAFgaSNkf5e
# Et4GLcuOzkcVmH2NiVD2fFlk3mdRsR0DmtWXx9IJgA5aPmILAb1hmH/vkBo5fe2p
# fXtbFkaIDTC2cpPIKWhq7BsXOFqRav8Agbdd6uPeGIN53Ljj12Cij4li4UXp7dNp
# GrypLJcXgYHxS6N4NQthUczOiJyF8EjH7wTaTGhCzSpsoyQ/PnH0fBuQZida8Sxf
# ENy8S2H7XMdqr6sEPf8hD7zFwv0XfxgZ4IvloQ70cAjNJu97h1XdFjw0Bgb9YJk+
# RpRdWj+oo7OewT+djmxzyg==
# SIG # End signature block
