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
            Write-Log "ERROR: Could not find adapters. Public Found: $($null -ne $publicConn), Private Found: $($null -ne $privateConn)"
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

