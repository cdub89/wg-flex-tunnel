# WireGuard Flex Tunnel - ICS Automation for Windows 11


## Overview

This project automates **Internet Connection Sharing (ICS)** for WireGuard VPN tunnels on Windows 11. It enables your WireGuard tunnel to share its VPN connection with other network adapters (e.g., Wi-Fi, Ethernet, or virtual adapters) using WireGuard's `PostUp` and `PostDown` script hooks.

The goal is to share your WireGuard VPN connection from one adapter to another, allowing multiple devices or VMs to route traffic through your VPN tunnel.  

**Use Case**: Enabled your MORCONI (morse code network interface) to connect securely from your laptop to the remote FlexRadio Station without requiring extra hardware or cables (travel router etc).  

The MORCONI network device should be plugged into the USB port of the Win11 PC/Laptop.  The MORCONI requires a VPN tunnel to the remote site to access port 4992 on the private network where the Flexradio is hosted. 

 Once the VPN tunnel is up you can test the network connection with the tnc (test network connection) command.   
 
   tnc {FlexRadio IP Address} -Port 4992

   Expected Output:

   TcpTestSucceeded : True

Note:  On my laptop, "WG-Flex" is the tunnel name I chose in the Wireguard "Add Tunnel" step.  I renamed "Ethernet 2" to Morconi for convenience in the Win11 Network Connections screen.

---

## Features

- ✅ Automatic ICS enablement when WireGuard tunnel connects
- ✅ Automatic ICS cleanup when WireGuard tunnel disconnects
- ✅ Prevents IP conflicts by resetting DHCP on shared adapter
- ✅ Service health validation during operations
- ✅ Comprehensive logging for troubleshooting
- ✅ Health check and diagnostic tools included

---

## Prerequisites

### 1. Administrator Privileges
All scripts **must be run as Administrator** to modify network settings and manage ICS.

### 2. Required Windows Services
The following services must be enabled and running:
- **BFE** (Base Filtering Engine) - Required for WireGuard
- **SharedAccess** (Internet Connection Sharing)
- **nsi** (Network Store Interface)
- **NetSetupSvc** (Network Setup Service)
- **wireguard** (WireGuard Tunnel Service)

### 3. PowerShell Execution Policy
Ensure PowerShell can run scripts:
```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

---

## Installation

### Step 1: Apply Registry Settings

1. **Double-click** `Win11_VPN-Reg-Fix.reg` to apply required registry settings
2. Click **Yes** when prompted by UAC
3. **Restart your computer** for changes to take effect

**What it does:**
- Enables WireGuard's `PostUp`/`PostDown` script execution
- Configures UDP encapsulation for NAT traversal (critical for VPN + ICS)
- Disables ICS persistence to allow script control

### Step 2: Configure Adapter Names

1. Open **Network Connections** (`ncpa.cpl` or Win+R → `ncpa.cpl`)
2. Identify your adapter names:
   - **Public Adapter**: Your WireGuard tunnel adapter (e.g., "WG-Flex")
   - **Private Adapter**: The adapter you want to share TO (e.g., "Ethernet", "Wi-Fi", "Morconi")

3. Edit `WireGuard-ICS.ps1` and update lines 3-4:
```powershell
$publicAdapterName = "WG-Flex"    # Your WireGuard tunnel name
$privateAdapterName = "Morconi"   # Your adapter to share connection to
```

### Step 3: Update Log File Path (Optional)

By default, logs are saved to:
```
C:\Morconi\wg-flex-tunnel\wg_vpn_tunnel.log
```

To change the log location, edit line 5 in `WireGuard-ICS.ps1`:
```powershell
$logFile = "C:\Your\Custom\Path\wg_vpn_tunnel.log"
```

---

## WireGuard Configuration

### Editing Your WireGuard Tunnel Configuration

1. Open **WireGuard GUI** and click **Edit** on your tunnel
2. Add the following lines to the `[Interface]` section:

```ini
[Interface]
PrivateKey = YOUR_PRIVATE_KEY_HERE
Address = YOUR_VPN_IP_HERE
DNS = YOUR_DNS_HERE

# PostUp: Enable ICS when tunnel connects
PostUp = powershell.exe -ExecutionPolicy Bypass -File "C:\Morconi\wg-flex-tunnel\WireGuard-ICS.ps1" -Action Enable

# PostDown: Disable ICS when tunnel disconnects
PostDown = powershell.exe -ExecutionPolicy Bypass -File "C:\Morconi\wg-flex-tunnel\WireGuard-ICS.ps1" -Action Disable

[Peer]
PublicKey = SERVER_PUBLIC_KEY_HERE
Endpoint = SERVER_IP:PORT
AllowedIPs = 0.0.0.0/0, ::/0
```

### Important Notes:

- **Use full absolute paths** in `PostUp`/`PostDown` commands
- Update the path if you installed the scripts elsewhere
- `-ExecutionPolicy Bypass` allows the script to run without modifying system-wide PowerShell policies
- The script will be executed automatically by WireGuard with elevated privileges
- Uncheck the box for "Block untunneled traffic (kill-switch).  When enabled, it forces all traffic through the VPN, preventing DNS leaks, but restricts access to local LAN devices.


---

## Usage

### Automatic Operation (Recommended)

Once configured, the ICS automation works automatically:

1. **Activate your WireGuard tunnel** in WireGuard GUI
   - `PostUp` script runs → ICS enabled
   - WireGuard adapter shares connection to your private adapter
   - Private adapter receives IP `192.168.137.x` from ICS

2. **Deactivate your WireGuard tunnel**
   - `PostDown` script runs → ICS disabled
   - SharedAccess service stopped
   - Network returns to normal state

### Manual Operation (Testing/Troubleshooting)

You can also run the script manually:

```powershell
# Enable ICS
powershell.exe -ExecutionPolicy Bypass -File "C:\Morconi\wg-flex-tunnel\WireGuard-ICS.ps1" -Action Enable

# Disable ICS
powershell.exe -ExecutionPolicy Bypass -File "C:\Morconi\wg-flex-tunnel\WireGuard-ICS.ps1" -Action Disable
```

**When to use manual mode:**
- Testing configuration before adding to WireGuard
- Troubleshooting ICS issues
- Forcing ICS cleanup after errors

---

## Diagnostic Tools

### Health Check Script

Run `VPN-HealthCheck.ps1` to verify your system is configured correctly:

```powershell
powershell.exe -ExecutionPolicy Bypass -File "C:\Morconi\wg-flex-tunnel\VPN-HealthCheck.ps1"
```

**It checks:**
- ✅ Registry settings are correct
- ✅ Required services are running
- ✅ ICS is active (if WireGuard is connected)

**Color-coded output:**
- 🟢 Green = OK
- 🔴 Red = FAIL (needs attention)
- 🟡 Yellow = NOTICE (informational)

### Log File Monitoring

View real-time logs to monitor script operations:

```powershell
Get-Content "C:\Morconi\wg-flex-tunnel\wg_vpn_tunnel.log" -Tail 20 -Wait
```

**Log entry format:**
```
2026-01-03 14:32:15 - Starting WireGuard-ICS Post Up Process.
2026-01-03 14:32:15 - Resetting Morconi to DHCP to prevent IP conflicts...
2026-01-03 14:32:25 - Waiting 10 seconds for network stack to settle...
2026-01-03 14:32:35 - Attempting to Enable ICS...
2026-01-03 14:32:36 - SUCCESS: ICS enabled from WG-Flex to Morconi.
2026-01-03 14:32:36 - COMPLETE: WireGuard-ICS Post Up Process Complete.
```

---

## Troubleshooting

### Issue: "Could not find adapters" Error

**Symptoms:** Log shows `ERROR: Could not find adapters`

**Solutions:**
1. Verify adapter names in `ncpa.cpl` match `WireGuard-ICS.ps1` exactly (case-sensitive)
2. Wait 10-15 seconds after WireGuard connects before checking
3. Ensure WireGuard tunnel is active when enabling ICS
4. Restart WireGuard service: 
   ```powershell
   Restart-Service wireguard
   ```

### Issue: ICS Not Working After Connection

**Symptoms:** WireGuard connects but shared adapter has no internet

**Solutions:**
1. Run `VPN-HealthCheck.ps1` to verify system configuration
2. Check if BFE and SharedAccess services are running:
   ```powershell
   Get-Service BFE, SharedAccess
   ```
3. Verify private adapter received IP address from ICS:
   ```powershell
   Get-NetIPAddress -InterfaceAlias "Morconi" -AddressFamily IPv4
   ```
   Expected: `192.168.137.x`

4. Restart network stack using `reset.ps1` (requires reboot)

### Issue: ICS Persists After Disconnecting VPN

**Symptoms:** ICS remains active after WireGuard disconnects

**Solutions:**
1. Manually run disable command:
   ```powershell
   powershell.exe -ExecutionPolicy Bypass -File "C:\Morconi\wg-flex-tunnel\WireGuard-ICS.ps1" -Action Disable
   ```

2. Verify registry setting (should be 0):
   ```powershell
   Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\SharedAccess" -Name EnableRebootPersistConnection
   ```

3. If value is 1, re-apply `Win11_VPN-Reg-Fix.reg` and reboot

### Issue: Services Won't Start

**Symptoms:** BFE or SharedAccess service fails to start

**Solutions:**
1. Check service dependencies:
   ```powershell
   Get-Service BFE -RequiredServices
   ```

2. Run full network reset:
   ```powershell
   powershell.exe -ExecutionPolicy Bypass -File "C:\Morconi\wg-flex-tunnel\reset.ps1"
   ```
   **⚠️ Requires reboot**

3. Check Windows Firewall is enabled (BFE dependency)

### Issue: PostUp Script Not Executing

**Symptoms:** WireGuard connects but ICS doesn't enable

**Solutions:**
1. Verify `DangerousScriptExecution` registry key is set:
   ```powershell
   Get-ItemProperty "HKLM:\SOFTWARE\WireGuard" -Name DangerousScriptExecution
   ```
   Expected value: `1`

2. Check WireGuard logs for script errors:
   - WireGuard GUI → View logs
   - Look for PowerShell execution errors

3. Test script manually to verify it works:
   ```powershell
   powershell.exe -ExecutionPolicy Bypass -File "C:\Morconi\wg-flex-tunnel\WireGuard-ICS.ps1" -Action Enable
   ```

4. Ensure paths in WireGuard config use double backslashes or forward slashes:
   ```ini
   # Good:
   PostUp = powershell.exe -ExecutionPolicy Bypass -File "C:\\Morconi\\wg-flex-tunnel\\WireGuard-ICS.ps1" -Action Enable
   # Or:
   PostUp = powershell.exe -ExecutionPolicy Bypass -File "C:/Morconi/wg-flex-tunnel/WireGuard-ICS.ps1" -Action Enable
   ```

---

## Advanced Configuration

### Custom Wait Times

If your network stack needs more time to settle, edit line 38 in `WireGuard-ICS.ps1`:

```powershell
Start-Sleep -Seconds 10  # Increase to 15 or 20 if needed
```

### Sharing Multiple Adapters

To share to multiple adapters, you'll need to:
1. Duplicate the ICS script with different adapter names
2. Add multiple `PostUp` commands to WireGuard config:

```ini
PostUp = powershell.exe -ExecutionPolicy Bypass -File "C:\path\script1.ps1" -Action Enable
PostUp = powershell.exe -ExecutionPolicy Bypass -File "C:\path\script2.ps1" -Action Enable
```

**Note:** Only one adapter can be the "public" (shared from) connection, but multiple adapters can be "private" (shared to).

---

## Network Stack Reset (Last Resort)

If ICS becomes completely broken, use `reset.ps1`:

```powershell
powershell.exe -ExecutionPolicy Bypass -File "C:\Morconi\wg-flex-tunnel\reset.ps1"
```

**What it does:**
1. Stops ICS and BFE services
2. Resets Winsock, TCP/IP, IPv4, and IPv6 stacks
3. Restarts BFE service

**⚠️ WARNING:** You **must reboot** after running this script.

---

## Understanding ICS Behavior

### How ICS Works

When enabled, ICS:
1. Assigns IP `192.168.137.1` to the **public** adapter (WireGuard)
2. Creates a DHCP server on the public adapter
3. Assigns IP `192.168.137.x` (2-254) to **private** adapter(s)
4. Routes traffic from private adapters through the public adapter
5. Performs NAT (Network Address Translation)

### Why Reset to DHCP?

The script resets the private adapter to DHCP (line 34-35) to prevent conflicts:
- Removes any static IP addresses
- Allows ICS to manage IP assignment automatically
- Prevents "IP already in use" errors

### The 10-Second Wait

After changing network configuration, Windows needs time to:
- Update routing tables
- Reinitialize network adapters
- Establish ICS services

The 10-second wait (line 38) ensures stability. Reduce at your own risk.

---

## Security Considerations

### Script Execution Risks

The registry setting `DangerousScriptExecution` is named so for a reason:
- WireGuard will execute **any** script in PostUp/PostDown
- Scripts run with **elevated privileges** (Administrator)
- Malicious WireGuard configs could execute harmful commands

**Best practices:**
1. Only import WireGuard configs from trusted sources
2. Review PostUp/PostDown commands before activating tunnels
3. Use full absolute paths (avoid relative paths or %variables%)
4. Keep scripts in a protected directory

### Network Security

ICS creates a local DHCP server and NAT:
- Devices on private adapter can access your VPN tunnel
- Ensure private adapter is connected to trusted devices only
- Consider firewall rules if sharing to public networks

---

## File Reference

| File | Purpose | Run As Admin? |
|------|---------|---------------|
| `WireGuard-ICS.ps1` | Main ICS automation script | ✅ Yes |
| `VPN-HealthCheck.ps1` | System health diagnostic | ✅ Yes |
| `Win11_VPN-Reg-Fix.reg` | Registry configuration | ✅ Yes |
| `reset.ps1` | Network stack reset utility | ✅ Yes |
| `wg_vpn_tunnel.log` | Operation log file | Auto-created |
| `README.md` | This documentation | - |

---

## FAQ

**Q: Can I use this with multiple WireGuard tunnels?**  
A: Yes, but you need to specify different adapter names for each tunnel config.

**Q: Will this work with other VPN solutions?**  
A: No, this is specifically designed for WireGuard's PostUp/PostDown hooks. However, you could adapt the script for manual use with other VPNs.

**Q: Do I need to disable Windows Firewall?**  
A: No! Keep it enabled. BFE (Base Filtering Engine) depends on it.

**Q: Can I share FROM Ethernet TO Wi-Fi?**  
A: Yes! This script works with any two adapters. Just update `$publicAdapterName` and `$privateAdapterName` accordingly.

**Q: What if my adapter names have spaces?**  
A: No problem. PowerShell handles spaces correctly when using quoted strings.

**Q: Why is ICS disabled on PostDown?**  
A: To clean up network configuration and prevent routing conflicts when VPN is not active.

---

## Contributing

If you make improvements to these scripts:
1. Test thoroughly with Enable and Disable actions
2. Verify logging output is clear and helpful
3. Check that service management is appropriate
4. Validate timing delays work on your system
5. Document any adapter name or configuration changes needed

---

## Support

For issues or questions:
1. Check `wg_vpn_tunnel.log` for detailed error messages
2. Run `VPN-HealthCheck.ps1` to diagnose configuration issues
3. Review Troubleshooting section above
4. Check WireGuard logs in WireGuard GUI

---

## License

This project is provided as-is for Windows 11 WireGuard ICS automation. Use at your own risk.

---

## Version History

- **v1.0** (2026-01-03) - Initial documentation release
  - Core ICS automation with PostUp/PostDown
  - Health check and diagnostic tools
  - Network stack reset utility
  - Comprehensive troubleshooting guide

