# 1. Stop the ICS and related services
Stop-Service -Name "SharedAccess" -Force -ErrorAction SilentlyContinue
Stop-Service -Name "BFE" -Force -ErrorAction SilentlyContinue

# 2. Reset the Network Stack
netsh winsock reset
netsh int ip reset
netsh interface ipv4 reset
netsh interface ipv6 reset

# 3. Clear out any stale DNS or ARP entries
#ipconfig /release
#ipconfig /flushdns
#ipconfig /renew

# 4. Restart the Base Filtering Engine (Essential for WireGuard)
Start-Service -Name "BFE"

Write-Host "Network Stack Reset Complete. Please REBOOT your computer now." -ForegroundColor Cyan

Write-Host "Pausing 15 seconds to review results.."
Start-Sleep -Seconds 15
