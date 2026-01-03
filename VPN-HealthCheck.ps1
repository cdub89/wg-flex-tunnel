Write-Host "--- Windows 11 VPN & ICS Health Check ---" -ForegroundColor Cyan

# 1. Check Registry Keys.   In my set up SharedAccess should be 0 (disabled persistance) based on my testing.
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
