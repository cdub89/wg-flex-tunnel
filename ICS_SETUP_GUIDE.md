# Internet Connection Sharing Setup Guide
## Connecting Morconi to Remote FlexRadio via WireGuard VPN on Windows 11

---

## Table of Contents
1. [Overview](#overview)
2. [Understanding the Network Architecture](#understanding-the-network-architecture)
3. [What is Internet Connection Sharing (ICS)?](#what-is-internet-connection-sharing-ics)
4. [Prerequisites](#prerequisites)
5. [Setup Method 1: Automated (Recommended)](#setup-method-1-automated-recommended)
6. [Setup Method 2: Manual Configuration](#setup-method-2-manual-configuration)
7. [Testing the Connection](#testing-the-connection)
8. [Troubleshooting](#troubleshooting)
9. [Advanced Topics](#advanced-topics)

---

## Overview

This guide explains how to use **Internet Connection Sharing (ICS)** on Windows 11 to allow a USB-connected Morconi device (morse code network interface) to access a remote FlexRadio over a WireGuard VPN tunnel.

**The Challenge:**  
Your Morconi device is a hardware network interface that needs to communicate with a FlexRadio station on a private remote network (port 4992). The Morconi doesn't have VPN capabilities built-in, so it can't directly connect through the WireGuard tunnel.

**The Solution:**  
Use Windows 11's Internet Connection Sharing (ICS) to share your WireGuard VPN connection with the Morconi's network adapter. This makes Windows act as a router/gateway, allowing the Morconi to route its traffic through the VPN tunnel transparently.

**Use Case Benefits:**
- ✅ No additional hardware needed (travel routers, switches, etc.)
- ✅ Portable solution perfect for laptop use
- ✅ Morconi device accesses remote network as if it were local
- ✅ Secure end-to-end encrypted connection via WireGuard
- ✅ Can be automated to enable/disable with VPN connection

---

## Understanding the Network Architecture

### Network Topology

```
Remote Network (Private)           Your Windows 11 Laptop              Morconi Device
┌─────────────────────┐            ┌─────────────────────┐            ┌──────────────┐
│                     │            │                     │            │              │
│  FlexRadio Station  │            │   WireGuard VPN     │            │   Morconi    │
│  (Port 4992)        │◄───────────┤   Tunnel Adapter    │◄───────────┤  USB Device  │
│  Private IP:        │  Encrypted │   "WG-Flex"         │    ICS     │              │
│  10.x.x.x or        │   Tunnel   │                     │  Sharing   │  Adapter:    │
│  192.168.x.x        │            │   ICS Public        │            │  "Morconi"   │
│                     │            │   (Shares FROM)     │            │              │
│                     │            │                     │            │  ICS Private │
└─────────────────────┘            │   ┌─────────────┐   │            │  (Shares TO) │
                                   │   │ ICS Gateway │   │            │              │
       Internet                    │   │ 192.168.137.1│  │            │  IP Address: │
          │                        │   └─────────────┘   │            │  192.168.137.x│
          │                        │                     │            │              │
          │                        │   Physical WiFi/    │            └──────────────┘
          └────────────────────────┤   Ethernet Adapter  │
                                   │   (Internet Access) │
                                   └─────────────────────┘
```

### Traffic Flow

1. **Morconi** sends data to FlexRadio (destination: 192.168.x.x:4992)
2. **Windows ICS** receives the traffic from Morconi adapter
3. **ICS NAT** translates source address and routes through WG-Flex tunnel
4. **WireGuard** encrypts and sends through VPN tunnel to remote endpoint
5. **Remote VPN Server** decrypts and forwards to FlexRadio on local network
6. **Response** follows the same path in reverse

### Key Components

| Component | Adapter Name | Purpose | IP Assignment |
|-----------|--------------|---------|---------------|
| **WireGuard Tunnel** | WG-Flex | VPN connection to remote site | Set by WireGuard config |
| **ICS Public** | WG-Flex | Shares connection FROM (ICS gateway) | 192.168.137.1 (ICS assigned) |
| **ICS Private** | Morconi | Shares connection TO | 192.168.137.x (DHCP from ICS) |
| **Morconi Device** | Morconi | Hardware interface to FlexRadio | Auto-assigned by ICS |

---

## What is Internet Connection Sharing (ICS)?

### ICS Explained

**Internet Connection Sharing** is a Windows feature that turns your computer into a basic router/gateway. When enabled:

1. **DHCP Server** - Windows creates a DHCP server that assigns IP addresses (192.168.137.2-254)
2. **Gateway** - Windows assigns itself 192.168.137.1 as the gateway address
3. **NAT (Network Address Translation)** - Translates private ICS addresses to the public connection
4. **Routing** - Forwards traffic between the shared adapter and the sharing adapter
5. **DNS Forwarding** - Forwards DNS requests through the shared connection

### Why ICS is Perfect for This Use Case

Traditional methods would require:
- 🚫 Hardware router with VPN client capability ($$$)
- 🚫 Complex bridging configuration (unreliable with VPNs)
- 🚫 Virtual machine with network sharing (resource intensive)

ICS provides:
- ✅ Built into Windows 11 (no additional software)
- ✅ Simple configuration (can be automated)
- ✅ Reliable NAT/routing through VPN tunnels
- ✅ Automatic DHCP for connected devices
- ✅ Can be enabled/disabled programmatically

### ICS Limitations

**Important to understand:**
- Only **one** adapter can be the "public" (sharing FROM) connection at a time
- ICS uses a **fixed subnet**: 192.168.137.0/24 (cannot be changed easily)
- ICS overrides any static IP configuration on private adapter
- Windows Firewall rules may need adjustment for device communication
- ICS creates shared connection persistence that needs to be disabled for script control

---

## Prerequisites

### Hardware Requirements
- ✅ Windows 11 PC or laptop with Administrator access
- ✅ Morconi device connected via USB
- ✅ Active internet connection for VPN
- ✅ Working WireGuard VPN configuration to remote site

### Software Requirements
- ✅ **WireGuard for Windows** installed ([download here](https://www.wireguard.com/install/))
- ✅ **PowerShell 5.1+** (included in Windows 11)
- ✅ **Administrator privileges** (required for network configuration)

### Network Requirements
- ✅ WireGuard tunnel configuration with access to remote FlexRadio network
- ✅ Remote network allows access to FlexRadio on port 4992
- ✅ DNS resolution working through VPN (test with `nslookup` through tunnel)

### Windows Services
The following services must be enabled and running:

| Service | Display Name | Required For | Check Command |
|---------|--------------|--------------|---------------|
| BFE | Base Filtering Engine | WireGuard operation | `Get-Service BFE` |
| SharedAccess | Internet Connection Sharing | ICS functionality | `Get-Service SharedAccess` |
| nsi | Network Store Interface | Network configuration | `Get-Service nsi` |
| NetSetupSvc | Network Setup Service | Adapter configuration | `Get-Service NetSetupSvc` |
| wireguard | WireGuard Tunnel Service | VPN tunnel | `Get-Service wireguard` |

**Verify services in PowerShell (as Administrator):**
```powershell
Get-Service BFE, SharedAccess, nsi, NetSetupSvc, wireguard | Select-Object Name, Status, StartType
```

All should show **Status: Running** and **StartType: Automatic**.

---

## Setup Method 1: Automated (Recommended)

The automated method uses PowerShell scripts that integrate with WireGuard's PostUp/PostDown hooks to automatically enable/disable ICS when you connect/disconnect the VPN.

### Step 1: Verify Network Adapter Names

1. Press **Win+R**, type `ncpa.cpl`, and press Enter
2. Identify your adapters:
   - **WireGuard Tunnel**: Look for an adapter named "WG-Flex" (or similar) - appears when VPN is connected
   - **Morconi Device**: Look for the USB network adapter (may be named "Ethernet", "Ethernet 2", etc.)

3. **(Recommended)** Rename adapters for clarity:
   - Right-click WireGuard adapter → **Rename** → `WG-Flex`
   - Right-click Morconi adapter → **Rename** → `Morconi`

**Note:** Adapter names are case-sensitive and must match exactly in the script.

### Step 2: Apply Registry Configuration

1. Locate `Win11_VPN-Reg-Fix.reg` in the project folder
2. **Right-click** → **Merge** (or double-click)
3. Click **Yes** on User Account Control (UAC) prompt
4. Click **Yes** to confirm adding to registry
5. **Restart your computer** for changes to take effect

**What this does:**
- Enables WireGuard script execution (`DangerousScriptExecution = 1`)
- Configures UDP encapsulation for NAT traversal (essential for VPN + ICS)
- Disables ICS persistence to allow script control

### Step 3: Configure Script Adapter Names

1. Open `WireGuard-ICS.ps1` in a text editor (Notepad, VSCode, etc.)
2. Update lines 3-4 with your actual adapter names:

```powershell
$publicAdapterName = "WG-Flex"    # Your WireGuard tunnel adapter name
$privateAdapterName = "Morconi"   # Your Morconi adapter name
```

3. (Optional) Update log file path on line 5:

```powershell
$logFile = "C:\Morconi\wg-flex-tunnel\wg_vpn_tunnel.log"
```

4. **Save the file**

### Step 4: Unblock PowerShell Scripts

Windows blocks execution of downloaded scripts by default:

```powershell
# Run in PowerShell as Administrator
cd "C:\Path\To\wg-flex-tunnel"

# Unblock all scripts
Unblock-File .\WireGuard-ICS.ps1
Unblock-File .\VPN-HealthCheck.ps1
Unblock-File .\reset.ps1
```

### Step 5: Update WireGuard Configuration

1. Open **WireGuard GUI**
2. Click **Edit** on your tunnel configuration
3. Add these lines to the `[Interface]` section:

```ini
[Interface]
PrivateKey = YOUR_PRIVATE_KEY_HERE
Address = YOUR_VPN_ADDRESS_HERE
DNS = YOUR_DNS_HERE

# Enable ICS when tunnel connects
PostUp = powershell.exe -ExecutionPolicy Bypass -File "C:\Morconi\wg-flex-tunnel\WireGuard-ICS.ps1" -Action Enable

# Disable ICS when tunnel disconnects
PostDown = powershell.exe -ExecutionPolicy Bypass -File "C:\Morconi\wg-flex-tunnel\WireGuard-ICS.ps1" -Action Disable

[Peer]
PublicKey = SERVER_PUBLIC_KEY_HERE
Endpoint = SERVER_IP:PORT
AllowedIPs = 0.0.0.0/0, ::/0
```

**Important Configuration Notes:**
- Use the **full absolute path** to the script (not relative paths)
- Update the path if you stored the scripts in a different location
- Replace `C:\Morconi\wg-flex-tunnel\` with your actual script location
- Ensure "Block untunneled traffic (kill-switch)" is **unchecked** if you need local LAN access

4. Click **Save**

### Step 6: Test the Automated Setup

1. **Activate WireGuard Tunnel**
   - Open WireGuard GUI
   - Click **Activate** on your tunnel
   - Wait 15-20 seconds for ICS to initialize

2. **Verify ICS is Active**
   - Open PowerShell as Administrator
   - Run: `Get-NetIPAddress -InterfaceAlias "Morconi" -AddressFamily IPv4`
   - You should see IP address: `192.168.137.x` (where x is 2-254)

3. **Check Log File**
   ```powershell
   Get-Content "C:\Morconi\wg-flex-tunnel\wg_vpn_tunnel.log" -Tail 20
   ```
   
   Look for:
   ```
   2026-01-13 XX:XX:XX - Starting WireGuard-ICS Post Up Process.
   2026-01-13 XX:XX:XX - Resetting Morconi to DHCP to prevent IP conflicts...
   2026-01-13 XX:XX:XX - Waiting 10 seconds for network stack to settle...
   2026-01-13 XX:XX:XX - Attempting to Enable ICS...
   2026-01-13 XX:XX:XX - SUCCESS: ICS enabled from WG-Flex to Morconi.
   2026-01-13 XX:XX:XX - COMPLETE: WireGuard-ICS Post Up Process Complete.
   ```

4. **Deactivate Tunnel**
   - Click **Deactivate** in WireGuard GUI
   - Check log for cleanup confirmation:
   ```
   2026-01-13 XX:XX:XX - Attempting to Disable ICS...
   2026-01-13 XX:XX:XX - SUCCESS: ICS disabled.
   2026-01-13 XX:XX:XX - COMPLETE: WireGuard-ICS Post Down Process Complete.
   ```

---

## Setup Method 2: Manual Configuration

If you prefer to configure ICS manually without automation, follow these steps. This is useful for understanding how ICS works or for one-time testing.

### Step 1: Verify Adapter Names

1. Press **Win+R**, type `ncpa.cpl`, press Enter
2. Note the exact names of:
   - WireGuard tunnel adapter (e.g., "WG-Flex")
   - Morconi network adapter (e.g., "Morconi")

### Step 2: Connect WireGuard VPN

1. Open **WireGuard GUI**
2. **Activate** your tunnel
3. Wait 10 seconds for tunnel to fully establish
4. Verify connection: `ping` a remote IP through the tunnel

### Step 3: Enable Internet Connection Sharing

#### GUI Method (Simplest)

1. Open **Network Connections** (Win+R → `ncpa.cpl`)
2. **Right-click** on the **WG-Flex** adapter (the WireGuard tunnel)
3. Select **Properties**
4. Click the **Sharing** tab
5. Check ☑ **"Allow other network users to connect through this computer's Internet connection"**
6. In the dropdown, select **"Morconi"** (your Morconi adapter)
7. Click **OK**

**What happens:**
- Windows assigns `192.168.137.1` to WG-Flex adapter
- Windows creates DHCP server on that subnet
- Morconi adapter will receive `192.168.137.x` via DHCP

8. **Wait 10-15 seconds** for ICS to fully initialize

#### PowerShell Method (For Scripting)

Run PowerShell **as Administrator**:

```powershell
# Reset Morconi adapter to DHCP (prevents IP conflicts)
Get-NetIPAddress -InterfaceAlias "Morconi" -AddressFamily IPv4 | Remove-NetIPAddress -Confirm:$false
Set-NetIPInterface -InterfaceAlias "Morconi" -Dhcp Enabled

# Wait for network stack to settle
Start-Sleep -Seconds 10

# Enable ICS via COM object
$netShare = New-Object -ComObject HNetCfg.HNetShare
$publicConn = $null
$privateConn = $null

foreach ($conn in $netShare.EnumEveryConnection) {
    $props = $netShare.NetConnectionProps($conn)
    if ($props.Name -eq "WG-Flex") {
        $publicConn = $netShare.INetSharingConfigurationForINetConnection($conn)
    }
    if ($props.Name -eq "Morconi") {
        $privateConn = $netShare.INetSharingConfigurationForINetConnection($conn)
    }
}

if ($publicConn -and $privateConn) {
    $publicConn.EnableSharing(0)   # 0 = Public (share FROM)
    $privateConn.EnableSharing(1)  # 1 = Private (share TO)
    Write-Host "ICS enabled successfully!" -ForegroundColor Green
} else {
    Write-Host "Error: Could not find adapters" -ForegroundColor Red
}
```

### Step 4: Verify ICS Configuration

Check Morconi adapter received correct IP:

```powershell
Get-NetIPAddress -InterfaceAlias "Morconi" -AddressFamily IPv4
```

**Expected output:**
- **IPAddress**: 192.168.137.x (where x is typically 2-254)
- **PrefixLength**: 24
- **PrefixOrigin**: DHCP

Check WG-Flex has gateway IP:

```powershell
Get-NetIPAddress -InterfaceAlias "WG-Flex" -AddressFamily IPv4
```

You should see **two** IP addresses:
- Your VPN tunnel IP (from WireGuard config)
- 192.168.137.1 (ICS gateway IP)

### Step 5: Verify Routing

Check routing table to confirm Morconi traffic routes through WG-Flex:

```powershell
Get-NetRoute -AddressFamily IPv4 | Where-Object { $_.DestinationPrefix -like "192.168.137.*" }
```

Should show route with:
- **NextHop**: 0.0.0.0 (on-link)
- **InterfaceAlias**: WG-Flex

### Step 6: Test Connectivity

From Morconi adapter's perspective, test reaching through VPN:

```powershell
# Test connectivity to FlexRadio port 4992
Test-NetConnection -ComputerName <FlexRadio_IP> -Port 4992

# Or using the tnc alias
tnc <FlexRadio_IP> -Port 4992
```

**Expected output:**
```
ComputerName     : 192.168.1.100
RemoteAddress    : 192.168.1.100
RemotePort       : 4992
InterfaceAlias   : Morconi
SourceAddress    : 192.168.137.x
TcpTestSucceeded : True
```

### Step 7: Disabling ICS (When Done)

#### GUI Method

1. Open **Network Connections** (Win+R → `ncpa.cpl`)
2. **Right-click** on the **WG-Flex** adapter
3. Select **Properties** → **Sharing** tab
4. Uncheck ☐ **"Allow other network users to connect"**
5. Click **OK**

#### PowerShell Method

```powershell
# Disable ICS on all adapters
$netShare = New-Object -ComObject HNetCfg.HNetShare
foreach ($conn in $netShare.EnumEveryConnection) {
    $config = $netShare.INetSharingConfigurationForINetConnection($conn)
    if ($config.SharingEnabled) {
        $config.DisableSharing()
    }
}

# Stop ICS service
Stop-Service -Name "SharedAccess" -Force

Write-Host "ICS disabled successfully!" -ForegroundColor Green
```

---

## Testing the Connection

### Test 1: Verify Morconi Network Configuration

```powershell
# Check Morconi adapter has ICS-assigned IP
Get-NetIPAddress -InterfaceAlias "Morconi" -AddressFamily IPv4
```

✅ **Pass Criteria:**
- IPAddress: 192.168.137.x (x between 2-254)
- PrefixOrigin: DHCP
- SuffixOrigin: DHCP

❌ **Fail:** If IP is different, ICS may not be active

### Test 2: Verify Gateway Configuration

```powershell
# Check default gateway for Morconi adapter
Get-NetRoute -InterfaceAlias "Morconi" -DestinationPrefix "0.0.0.0/0"
```

✅ **Pass Criteria:**
- NextHop: 192.168.137.1
- RouteMetric: Should be lower than other adapters

### Test 3: Ping Through ICS Gateway

```powershell
# Ping the ICS gateway from Morconi subnet perspective
Test-Connection -Source 192.168.137.1 -Count 4
```

✅ **Pass Criteria:** 
- All pings successful
- Response time < 5ms (local)

### Test 4: Test DNS Resolution Through VPN

```powershell
# Test DNS resolution works through VPN tunnel
Resolve-DnsName flexradio.local  # Use your actual hostname/IP
```

✅ **Pass Criteria:**
- Successfully resolves hostname
- Returns correct IP address

### Test 5: Test Remote FlexRadio Port Connectivity

```powershell
# Test TCP port 4992 connectivity to FlexRadio
Test-NetConnection -ComputerName <FlexRadio_IP> -Port 4992 -InformationLevel Detailed
```

✅ **Pass Criteria:**
```
ComputerName     : <FlexRadio_IP>
RemoteAddress    : <FlexRadio_IP>
RemotePort       : 4992
InterfaceAlias   : Morconi
SourceAddress    : 192.168.137.x
TcpTestSucceeded : True
PingSucceeded    : True
PingReplyDetails (RTT): XX ms
```

❌ **Fail Scenarios:**
- **TcpTestSucceeded: False** → Port blocked or FlexRadio not listening
- **No route to host** → VPN routing issue or AllowedIPs misconfiguration
- **Connection timeout** → Firewall blocking port 4992

### Test 6: Check WireGuard Traffic Statistics

```powershell
# In WireGuard GUI, check "Transfer" statistics
# Should show increasing RX/TX bytes when testing
```

✅ **Pass Criteria:**
- Transfer counters increase when accessing FlexRadio
- Latest handshake timestamp is recent (< 3 minutes old)

### Test 7: Verify Services Health

```powershell
# Run the health check script
powershell.exe -ExecutionPolicy Bypass -File "C:\Morconi\wg-flex-tunnel\VPN-HealthCheck.ps1"
```

✅ **Pass Criteria:**
- All services show green (OK)
- Registry settings correct
- ICS detected as active

### Test 8: End-to-End Application Test

**Using Morconi Application:**
1. Launch your Morconi/FlexRadio client application
2. Configure it to connect to FlexRadio IP on port 4992
3. Attempt connection

✅ **Pass Criteria:**
- Application successfully connects
- Can send/receive data
- No connection drops or timeouts

---

## Troubleshooting

### Issue 1: Morconi Adapter Not Getting IP Address

**Symptoms:**
- Morconi shows "No Internet access"
- IP address is 169.254.x.x (APIPA) or blank
- Cannot ping 192.168.137.1

**Diagnosis:**
```powershell
Get-NetIPAddress -InterfaceAlias "Morconi" -AddressFamily IPv4
Get-Service SharedAccess
```

**Solutions:**

1. **Verify SharedAccess service is running:**
   ```powershell
   Start-Service SharedAccess
   ```

2. **Reset Morconi adapter to DHCP:**
   ```powershell
   Get-NetIPAddress -InterfaceAlias "Morconi" | Remove-NetIPAddress -Confirm:$false
   Set-NetIPInterface -InterfaceAlias "Morconi" -Dhcp Enabled
   Restart-NetAdapter -Name "Morconi"
   ```

3. **Wait longer for DHCP:**
   - ICS DHCP can take 15-20 seconds to assign IP
   - Try: `ipconfig /renew "Morconi"`

4. **Check for IP conflicts:**
   ```powershell
   # Release any existing IP and request fresh DHCP
   ipconfig /release "Morconi"
   Start-Sleep -Seconds 5
   ipconfig /renew "Morconi"
   ```

5. **Verify ICS is actually enabled:**
   ```powershell
   # Check ICS status via registry
   Get-ItemProperty "HKLM:\System\CurrentControlSet\Services\SharedAccess\Parameters\Connections" -ErrorAction SilentlyContinue
   ```

### Issue 2: "Could Not Find Adapters" Error

**Symptoms:**
- Log shows: `ERROR: Could not find adapters`
- Script completes but ICS not enabled

**Diagnosis:**
Check exact adapter names:
```powershell
Get-NetAdapter | Select-Object Name, InterfaceDescription, Status
```

**Solutions:**

1. **Verify adapter names match exactly:**
   - Open `ncpa.cpl`
   - Check WireGuard adapter name (case-sensitive!)
   - Check Morconi adapter name (case-sensitive!)
   - Update `WireGuard-ICS.ps1` lines 3-4 with exact names

2. **Ensure WireGuard tunnel is connected first:**
   - WG-Flex adapter only appears when tunnel is active
   - Connect VPN, then wait 10 seconds before running script

3. **Check for hidden characters in adapter names:**
   ```powershell
   Get-NetAdapter | Where-Object {$_.Name -like "*Flex*"} | Select-Object Name | Format-Hex
   ```

4. **Try renaming adapters to simple names:**
   - Avoid spaces, special characters
   - Use simple names like "WG-Flex" and "Morconi"

### Issue 3: ICS Enabled But No Internet on Morconi

**Symptoms:**
- Morconi has 192.168.137.x IP address
- Can ping 192.168.137.1 (gateway)
- Cannot reach internet or VPN resources

**Diagnosis:**
```powershell
# Check routing table
Get-NetRoute -InterfaceAlias "Morconi" -DestinationPrefix "0.0.0.0/0"

# Check DNS configuration
Get-DnsClientServerAddress -InterfaceAlias "Morconi"

# Test gateway reachability
Test-NetConnection -ComputerName 192.168.137.1 -TraceRoute
```

**Solutions:**

1. **Verify WireGuard AllowedIPs includes target network:**
   - Edit WireGuard config
   - Ensure `AllowedIPs` includes remote FlexRadio network
   - Example: `AllowedIPs = 0.0.0.0/0, ::/0` or `AllowedIPs = 192.168.1.0/24, 10.0.0.0/8`

2. **Check Windows Firewall rules:**
   ```powershell
   # Temporarily disable to test (re-enable after!)
   Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False
   
   # Test connectivity
   # If works, you need to add firewall rules
   
   # Re-enable firewall
   Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True
   ```

3. **Add firewall rules for ICS:**
   ```powershell
   # Allow ICS traffic
   New-NetFirewallRule -DisplayName "ICS - Morconi Allow All" `
       -Direction Inbound `
       -InterfaceAlias "Morconi" `
       -Action Allow
   ```

4. **Verify NAT is working:**
   ```powershell
   # Check NAT translations
   Get-NetNat
   Get-NetNatSession
   ```

5. **Check DNS forwarding:**
   ```powershell
   # Verify DNS servers are set on Morconi
   Set-DnsClientServerAddress -InterfaceAlias "Morconi" -ServerAddresses "192.168.137.1"
   ```

### Issue 4: FlexRadio Port 4992 Not Reachable

**Symptoms:**
- Internet works through ICS
- Cannot connect to FlexRadio on port 4992
- `tnc <FlexRadio_IP> -Port 4992` fails

**Diagnosis:**
```powershell
# Test from Windows directly (not through Morconi)
Test-NetConnection -ComputerName <FlexRadio_IP> -Port 4992

# Check if port is listening
Test-NetConnection -ComputerName <FlexRadio_IP> -Port 4992 -InformationLevel Detailed

# Trace route to FlexRadio
Test-NetConnection -ComputerName <FlexRadio_IP> -TraceRoute
```

**Solutions:**

1. **Verify FlexRadio is powered on and accessible:**
   ```powershell
   # Can you ping the FlexRadio?
   Test-Connection <FlexRadio_IP> -Count 4
   ```

2. **Check if issue is Windows-only or Morconi-specific:**
   - Test from Windows directly
   - If Windows can connect but Morconi cannot → ICS routing issue
   - If neither can connect → VPN or remote network issue

3. **Verify VPN routing:**
   ```powershell
   # Check route to FlexRadio network exists
   Get-NetRoute -DestinationPrefix "<FlexRadio_Network>/24"
   
   # Example: If FlexRadio is 192.168.1.100
   Get-NetRoute -DestinationPrefix "192.168.1.0/24"
   ```

4. **Check remote firewall rules:**
   - Contact remote network admin
   - Ensure port 4992 is open for VPN clients
   - Check if FlexRadio device firewall allows connections

5. **Verify WireGuard peer configuration:**
   - Edit WireGuard tunnel
   - Check `AllowedIPs` includes FlexRadio network
   - Example: `AllowedIPs = 192.168.1.0/24` or `AllowedIPs = 0.0.0.0/0`

6. **Test with telnet (if available):**
   ```powershell
   # Install telnet client if needed
   Add-WindowsCapability -Online -Name "TelnetClient~~~~0.0.1.0"
   
   # Test port
   telnet <FlexRadio_IP> 4992
   ```

### Issue 5: ICS Persists After Disconnecting VPN

**Symptoms:**
- WireGuard disconnected
- ICS still active on adapters
- Morconi still has 192.168.137.x IP

**Diagnosis:**
```powershell
# Check if SharedAccess service is still running
Get-Service SharedAccess

# Check if ICS is still configured
Get-NetIPAddress -IPAddress "192.168.137.1" -ErrorAction SilentlyContinue
```

**Solutions:**

1. **Manually disable ICS:**
   ```powershell
   powershell.exe -ExecutionPolicy Bypass -File "C:\Morconi\wg-flex-tunnel\WireGuard-ICS.ps1" -Action Disable
   ```

2. **Stop SharedAccess service:**
   ```powershell
   Stop-Service -Name SharedAccess -Force
   ```

3. **Verify registry setting:**
   ```powershell
   Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\SharedAccess" -Name EnableRebootPersistConnection
   ```
   - Value should be `0` (disabled)
   - If `1`, re-apply `Win11_VPN-Reg-Fix.reg` and reboot

4. **Reset adapter to DHCP:**
   ```powershell
   Get-NetIPAddress -InterfaceAlias "Morconi" | Remove-NetIPAddress -Confirm:$false
   Set-NetIPInterface -InterfaceAlias "Morconi" -Dhcp Enabled
   Restart-NetAdapter -Name "Morconi"
   ```

### Issue 6: PostUp Script Not Executing

**Symptoms:**
- WireGuard connects successfully
- ICS never enables automatically
- No entries in log file after connection

**Diagnosis:**
```powershell
# Check if DangerousScriptExecution is enabled
Get-ItemProperty "HKLM:\SOFTWARE\WireGuard" -Name DangerousScriptExecution

# Check WireGuard logs (in WireGuard GUI → View Logs)
```

**Solutions:**

1. **Verify registry setting:**
   ```powershell
   # Should return 1
   Get-ItemProperty "HKLM:\SOFTWARE\WireGuard" -Name DangerousScriptExecution
   
   # If not 1, set it:
   Set-ItemProperty "HKLM:\SOFTWARE\WireGuard" -Name DangerousScriptExecution -Value 1 -Type DWord
   ```

2. **Check script path in WireGuard config:**
   - Edit tunnel in WireGuard GUI
   - Verify PostUp path is absolute, not relative
   - Use forward slashes or double backslashes:
     ```ini
     # Good
     PostUp = powershell.exe -ExecutionPolicy Bypass -File "C:/Morconi/wg-flex-tunnel/WireGuard-ICS.ps1" -Action Enable
     
     # Also good
     PostUp = powershell.exe -ExecutionPolicy Bypass -File "C:\\Morconi\\wg-flex-tunnel\\WireGuard-ICS.ps1" -Action Enable
     
     # Bad
     PostUp = powershell.exe -ExecutionPolicy Bypass -File ".\WireGuard-ICS.ps1" -Action Enable
     ```

3. **Test script manually:**
   ```powershell
   # Connect VPN first, then run:
   powershell.exe -ExecutionPolicy Bypass -File "C:\Morconi\wg-flex-tunnel\WireGuard-ICS.ps1" -Action Enable
   
   # Check for errors
   ```

4. **Check PowerShell execution policy:**
   ```powershell
   Get-ExecutionPolicy -List
   
   # Set if needed
   Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

5. **Verify script is not blocked:**
   ```powershell
   Unblock-File "C:\Morconi\wg-flex-tunnel\WireGuard-ICS.ps1"
   ```

6. **Restart WireGuard service:**
   ```powershell
   Restart-Service wireguard
   ```

### Issue 7: Services Not Starting

**Symptoms:**
- BFE or SharedAccess won't start
- Error: "Cannot start service" or "Service dependency failed"

**Diagnosis:**
```powershell
# Check service status and dependencies
Get-Service BFE, SharedAccess | Select-Object Name, Status, StartType
Get-Service BFE -RequiredServices
Get-Service SharedAccess -RequiredServices

# Check event logs
Get-EventLog -LogName System -Source "Service Control Manager" -Newest 20 | Where-Object {$_.Message -like "*SharedAccess*" -or $_.Message -like "*BFE*"}
```

**Solutions:**

1. **Enable dependency services:**
   ```powershell
   # BFE dependencies
   Set-Service -Name "nsi" -StartupType Automatic
   Start-Service nsi
   
   # SharedAccess dependencies
   Set-Service -Name "NetSetupSvc" -StartupType Manual
   Set-Service -Name "BFE" -StartupType Automatic
   Start-Service BFE
   ```

2. **Verify Windows Firewall is enabled:**
   ```powershell
   Get-Service mpssvc  # Windows Firewall service
   
   # Enable if disabled
   Set-Service -Name "mpssvc" -StartupType Automatic
   Start-Service mpssvc
   ```

3. **Run network reset utility:**
   ```powershell
   powershell.exe -ExecutionPolicy Bypass -File "C:\Morconi\wg-flex-tunnel\reset.ps1"
   ```
   **⚠️ Requires reboot after running!**

4. **Check for Group Policy restrictions:**
   ```powershell
   # Check if GPO is blocking services
   gpresult /H c:\gpreport.html
   # Open c:\gpreport.html and search for "SharedAccess" or "BFE"
   ```

### Issue 8: Slow Connection or High Latency

**Symptoms:**
- Connection works but very slow
- High ping times (> 500ms)
- Frequent timeouts

**Diagnosis:**
```powershell
# Test latency to various points
Test-NetConnection -ComputerName 192.168.137.1 -TraceRoute  # ICS gateway
Test-NetConnection -ComputerName <VPN_Gateway_IP> -TraceRoute  # VPN server
Test-NetConnection -ComputerName <FlexRadio_IP> -TraceRoute  # FlexRadio

# Check VPN throughput
# In WireGuard GUI, watch transfer rate while sending data
```

**Solutions:**

1. **Check VPN server load:**
   - High latency may be VPN server issue, not ICS
   - Test direct Windows connection (without ICS) for comparison

2. **Reduce MTU size:**
   ```powershell
   # Set lower MTU on WireGuard adapter
   Set-NetIPInterface -InterfaceAlias "WG-Flex" -NlMtuBytes 1420
   
   # Also try on Morconi
   Set-NetIPInterface -InterfaceAlias "Morconi" -NlMtuBytes 1400
   ```

3. **Disable receive-side scaling on Morconi:**
   ```powershell
   Disable-NetAdapterRss -Name "Morconi"
   ```

4. **Prioritize VPN traffic:**
   ```powershell
   # Set higher adapter priority for WG-Flex
   Set-NetIPInterface -InterfaceAlias "WG-Flex" -InterfaceMetric 5
   ```

5. **Check system resources:**
   - Open Task Manager
   - Look for high CPU usage (crypto operations)
   - Check network utilization

### Issue 9: Connection Drops Intermittently

**Symptoms:**
- Connection works initially
- Drops after a few minutes
- Requires VPN reconnection to restore

**Diagnosis:**
```powershell
# Monitor connection stability
while ($true) {
    Test-NetConnection -ComputerName <FlexRadio_IP> -Port 4992 | Select-Object TcpTestSucceeded, @{Name="Time";Expression={Get-Date}}
    Start-Sleep -Seconds 30
}

# Check WireGuard handshakes
# In WireGuard GUI, watch "Latest handshake" timestamp
# Should update every 2-3 minutes
```

**Solutions:**

1. **Verify persistent keepalive in WireGuard:**
   Edit tunnel config, add to `[Peer]` section:
   ```ini
   [Peer]
   PublicKey = ...
   Endpoint = ...
   AllowedIPs = ...
   PersistentKeepalive = 25  # Send keepalive every 25 seconds
   ```

2. **Check for power management issues:**
   ```powershell
   # Disable power management on network adapters
   $adapter = Get-NetAdapter -Name "Morconi"
   $adapter | Set-NetAdapterPowerManagement -DeviceWakeupDisable -DeviceSelectiveSuspendDisable
   
   # Also for WireGuard adapter
   $wgAdapter = Get-NetAdapter -Name "WG-Flex"
   $wgAdapter | Set-NetAdapterPowerManagement -DeviceWakeupDisable
   ```

3. **Check for conflicting software:**
   - Other VPN clients (Cisco AnyConnect, GlobalProtect, etc.)
   - Network optimization tools
   - Antivirus/firewall software
   - Disable temporarily to test

4. **Monitor system logs for errors:**
   ```powershell
   # Check for network-related errors
   Get-EventLog -LogName System -Newest 50 | Where-Object {$_.EntryType -eq "Error" -and ($_.Message -like "*network*" -or $_.Message -like "*adapter*")}
   ```

### Issue 10: "Access Denied" When Running Script

**Symptoms:**
- Script fails with "Access denied" or "UnauthorizedAccess"
- Cannot modify network settings

**Solutions:**

1. **Ensure running PowerShell as Administrator:**
   - Right-click PowerShell icon
   - Select "Run as Administrator"
   - Window title should show "Administrator"

2. **Check UAC settings:**
   - Scripts must run elevated
   - WireGuard executes scripts with its privileges

3. **Verify file permissions:**
   ```powershell
   # Check script file permissions
   Get-Acl "C:\Morconi\wg-flex-tunnel\WireGuard-ICS.ps1" | Select-Object -ExpandProperty Access
   ```

4. **Run from correct location:**
   - Script must be on local drive (not network share)
   - Avoid paths with special characters

---

## Advanced Topics

### Understanding ICS IP Assignment

ICS uses a **fixed subnet**: `192.168.137.0/24`

| IP Address | Purpose | Notes |
|------------|---------|-------|
| 192.168.137.0 | Network address | Not usable |
| 192.168.137.1 | ICS Gateway (Windows) | Assigned to "public" adapter |
| 192.168.137.2-254 | DHCP Pool | Assigned to "private" adapter(s) |
| 192.168.137.255 | Broadcast address | Not usable |

**Key Facts:**
- Subnet **cannot be changed** without registry hacks (not recommended)
- First device (Morconi) usually gets `.2`
- DHCP lease time: 24 hours default
- Windows provides DHCP, DNS forwarding, and NAT

### Customizing ICS Subnet (Advanced - Not Recommended)

While possible, changing the ICS subnet requires registry modifications and can cause instability. Only attempt if absolutely necessary:

```powershell
# WARNING: Can break ICS functionality!
# Change ICS subnet to 10.0.0.0/24 example

# Stop ICS
Stop-Service SharedAccess

# Modify registry (THIS IS UNSUPPORTED!)
Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Services\SharedAccess\Parameters" -Name "ScopeAddress" -Value "10.0.0.1"
Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Services\SharedAccess\Parameters" -Name "ScopeAddressBackup" -Value "10.0.0.1"
Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Services\SharedAccess\Parameters" -Name "StandaloneDhcpAddress" -Value "10.0.0.1"

# Restart ICS
Start-Service SharedAccess

# ⚠️ This may not work reliably and can cause issues!
```

**Recommendation:** Accept the default 192.168.137.0/24 subnet unless you have a critical conflict.

### Multiple Private Adapters (One Public, Multiple Private)

ICS supports sharing one public connection to **multiple** private adapters:

```powershell
# Assuming "WG-Flex" is public
# Share to multiple private adapters: "Morconi" and "Ethernet2"

$netShare = New-Object -ComObject HNetCfg.HNetShare
$publicConn = $null
$privateConn1 = $null
$privateConn2 = $null

foreach ($conn in $netShare.EnumEveryConnection) {
    $props = $netShare.NetConnectionProps($conn)
    if ($props.Name -eq "WG-Flex") { 
        $publicConn = $netShare.INetSharingConfigurationForINetConnection($conn) 
    }
    if ($props.Name -eq "Morconi") { 
        $privateConn1 = $netShare.INetSharingConfigurationForINetConnection($conn) 
    }
    if ($props.Name -eq "Ethernet2") { 
        $privateConn2 = $netShare.INetSharingConfigurationForINetConnection($conn) 
    }
}

if ($publicConn) {
    $publicConn.EnableSharing(0)  # Public connection
}

if ($privateConn1) {
    $privateConn1.EnableSharing(1)  # Private connection 1
}

if ($privateConn2) {
    $privateConn2.EnableSharing(1)  # Private connection 2
}
```

Both private adapters will:
- Receive IPs in 192.168.137.0/24 range
- Use 192.168.137.1 as gateway
- Route through the WG-Flex tunnel

### Firewall Rules for ICS

Create specific firewall rules to allow Morconi traffic:

```powershell
# Allow all inbound on Morconi adapter
New-NetFirewallRule -DisplayName "ICS - Morconi Allow Inbound" `
    -Direction Inbound `
    -InterfaceAlias "Morconi" `
    -Action Allow `
    -Enabled True

# Allow all outbound on Morconi adapter
New-NetFirewallRule -DisplayName "ICS - Morconi Allow Outbound" `
    -Direction Outbound `
    -InterfaceAlias "Morconi" `
    -Action Allow `
    -Enabled True

# Allow FlexRadio port 4992 specifically
New-NetFirewallRule -DisplayName "FlexRadio Port 4992" `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort 4992 `
    -Action Allow `
    -Enabled True

# Allow ICMP (ping) on Morconi
New-NetFirewallRule -DisplayName "ICS - Morconi Allow ICMPv4" `
    -Direction Inbound `
    -Protocol ICMPv4 `
    -InterfaceAlias "Morconi" `
    -Action Allow `
    -Enabled True
```

### Monitoring ICS with Performance Counters

Monitor ICS performance metrics:

```powershell
# Network throughput on adapters
Get-Counter -Counter "\Network Interface(Morconi)\Bytes Total/sec" -SampleInterval 1 -MaxSamples 10

# ICS DHCP activity
Get-Counter -Counter "\SharedAccess\Current Clients" -Continuous

# NAT translations
Get-NetNatSession | Measure-Object

# Monitor continuously
while ($true) {
    Clear-Host
    Write-Host "=== ICS Monitoring ===" -ForegroundColor Cyan
    Write-Host ""
    
    # Adapter stats
    $stats = Get-NetAdapterStatistics -Name "Morconi", "WG-Flex"
    $stats | Format-Table Name, ReceivedBytes, SentBytes, ReceivedUnicastPackets, SentUnicastPackets -AutoSize
    
    # Connection test
    $test = Test-NetConnection -ComputerName <FlexRadio_IP> -Port 4992 -InformationLevel Quiet
    Write-Host "FlexRadio Port 4992: $(if($test){'OPEN'}else{'CLOSED'})" -ForegroundColor $(if($test){'Green'}else{'Red'})
    
    Start-Sleep -Seconds 5
}
```

### Packet Capture for Debugging

Capture packets to analyze traffic flow:

```powershell
# Start packet capture on Morconi adapter
$capture = New-NetEventSession -Name "MorconiCapture" -CaptureMode SaveToFile -LocalFilePath "C:\Temp\morconi_capture.etl" -MaxFileSize 100
Add-NetEventPacketCaptureProvider -SessionName "MorconiCapture" -Level 4 -CaptureType Physical -TruncationLength 256
Start-NetEventSession -Name "MorconiCapture"

# Let it run while you test
# Stop capture
Stop-NetEventSession -Name "MorconiCapture"
Remove-NetEventSession -Name "MorconiCapture"

# Convert to PCAP for Wireshark analysis
# Download etl2pcapng.exe from Microsoft
etl2pcapng.exe "C:\Temp\morconi_capture.etl" "C:\Temp\morconi_capture.pcap"

# Open in Wireshark to analyze
```

### Scripting ICS Status Checks

Create a monitoring script:

```powershell
function Get-ICSStatus {
    [CmdletBinding()]
    param(
        [string]$PublicAdapter = "WG-Flex",
        [string]$PrivateAdapter = "Morconi"
    )
    
    $result = [PSCustomObject]@{
        Timestamp = Get-Date
        SharedAccessService = (Get-Service SharedAccess).Status
        PublicAdapterStatus = (Get-NetAdapter -Name $PublicAdapter -ErrorAction SilentlyContinue).Status
        PrivateAdapterStatus = (Get-NetAdapter -Name $PrivateAdapter -ErrorAction SilentlyContinue).Status
        PrivateAdapterIP = (Get-NetIPAddress -InterfaceAlias $PrivateAdapter -AddressFamily IPv4 -ErrorAction SilentlyContinue).IPAddress
        GatewayIP = (Get-NetIPAddress -IPAddress "192.168.137.1" -ErrorAction SilentlyContinue).IPAddress
        ICSEnabled = $false
    }
    
    # Check if ICS is actually enabled
    $netShare = New-Object -ComObject HNetCfg.HNetShare
    foreach ($conn in $netShare.EnumEveryConnection) {
        $config = $netShare.INetSharingConfigurationForINetConnection($conn)
        if ($config.SharingEnabled) {
            $result.ICSEnabled = $true
            break
        }
    }
    
    return $result
}

# Use it
$status = Get-ICSStatus
$status | Format-List

# Log continuously
while ($true) {
    $status = Get-ICSStatus
    $status | Export-Csv -Path "C:\Temp\ics_status_log.csv" -Append -NoTypeInformation
    Start-Sleep -Seconds 60
}
```

### Optimizing WireGuard for ICS

WireGuard configuration tweaks for better ICS performance:

```ini
[Interface]
PrivateKey = YOUR_PRIVATE_KEY
Address = YOUR_VPN_IP
DNS = YOUR_DNS

# Reduce MTU to account for VPN + NAT overhead
MTU = 1420

# Scripts
PostUp = powershell.exe -ExecutionPolicy Bypass -File "C:\Morconi\wg-flex-tunnel\WireGuard-ICS.ps1" -Action Enable
PostDown = powershell.exe -ExecutionPolicy Bypass -File "C:\Morconi\wg-flex-tunnel\WireGuard-ICS.ps1" -Action Disable

[Peer]
PublicKey = SERVER_PUBLIC_KEY
Endpoint = SERVER_IP:PORT
AllowedIPs = 0.0.0.0/0, ::/0

# Keep connection alive through NAT
PersistentKeepalive = 25

# Optional: Add specific routes for FlexRadio network
# AllowedIPs = 192.168.1.0/24  # Replace with actual FlexRadio network
```

### Alternative: Using NAT without ICS (Advanced)

If ICS limitations are too restrictive, you can use Windows NAT feature directly:

```powershell
# Create NAT (requires Hyper-V, may conflict with ICS)
New-NetNat -Name "WireGuardNAT" -InternalIPInterfaceAddressPrefix "10.0.0.0/24"

# Configure internal address on WG-Flex
New-NetIPAddress -InterfaceAlias "WG-Flex" -IPAddress "10.0.0.1" -PrefixLength 24

# Configure DHCP server (requires additional setup)
# Consider third-party DHCP server or static IPs

# This approach is much more complex than ICS
# Only recommended for advanced users with specific requirements
```

### Automating Health Checks

Schedule health checks to run periodically:

```powershell
# Create scheduled task to run health check every hour
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File C:\Morconi\wg-flex-tunnel\VPN-HealthCheck.ps1"
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Hours 1)
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

Register-ScheduledTask -TaskName "WireGuard ICS Health Check" -Action $action -Trigger $trigger -Principal $principal -Settings $settings
```

---

## Summary

This guide covered:

✅ **How ICS works** and why it's needed for Morconi + FlexRadio + WireGuard  
✅ **Automated setup** using PowerShell scripts with PostUp/PostDown hooks  
✅ **Manual setup** for understanding the underlying process  
✅ **Comprehensive testing procedures** to verify connectivity  
✅ **Detailed troubleshooting** for common issues  
✅ **Advanced topics** for customization and monitoring  

### Quick Reference Commands

```powershell
# Check adapter IP addresses
Get-NetIPAddress -InterfaceAlias "Morconi" -AddressFamily IPv4

# Test FlexRadio connection
Test-NetConnection -ComputerName <FlexRadio_IP> -Port 4992

# Enable ICS manually
.\WireGuard-ICS.ps1 -Action Enable

# Disable ICS manually
.\WireGuard-ICS.ps1 -Action Disable

# Run health check
.\VPN-HealthCheck.ps1

# View logs
Get-Content "C:\Morconi\wg-flex-tunnel\wg_vpn_tunnel.log" -Tail 20

# Reset network (requires reboot)
.\reset.ps1
```

### Support Resources

- **Main README**: Comprehensive script documentation
- **Log File**: `C:\Morconi\wg-flex-tunnel\wg_vpn_tunnel.log`
- **Health Check**: `VPN-HealthCheck.ps1` for diagnostics
- **Network Reset**: `reset.ps1` for fixing broken network stack

---

**Document Version:** 1.0  
**Last Updated:** 2026-01-13  
**Author:** wg-flex-tunnel Project  
**License:** Use at your own risk
