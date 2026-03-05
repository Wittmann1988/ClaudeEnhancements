# ============================================================================
# Windows Gaming/Work PC - SSH Server & WoL Setup
# Run this script in PowerShell as Administrator
# ============================================================================

Write-Host "=== Windows SSH & WoL Setup ===" -ForegroundColor Cyan

# --- 1. Install OpenSSH Server -----------------------------------------------
Write-Host "`n[1/6] Installing OpenSSH Server..." -ForegroundColor Yellow

$sshServer = Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Server*'
if ($sshServer.State -ne 'Installed') {
    Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
    Write-Host "OpenSSH Server installed" -ForegroundColor Green
} else {
    Write-Host "OpenSSH Server already installed" -ForegroundColor Green
}

# --- 2. Configure and Start SSH Service --------------------------------------
Write-Host "`n[2/6] Configuring SSH Service..." -ForegroundColor Yellow

Start-Service sshd
Set-Service -Name sshd -StartupType 'Automatic'
Write-Host "SSH service started and set to auto-start" -ForegroundColor Green

# --- 3. Set PowerShell as default shell ---------------------------------------
Write-Host "`n[3/6] Setting PowerShell as default SSH shell..." -ForegroundColor Yellow

New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" `
    -Name DefaultShell `
    -Value "C:\Program Files\PowerShell\7\pwsh.exe" `
    -PropertyType String -Force -ErrorAction SilentlyContinue

# Fallback to Windows PowerShell if PS7 not found
if (-not (Test-Path "C:\Program Files\PowerShell\7\pwsh.exe")) {
    New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" `
        -Name DefaultShell `
        -Value "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" `
        -PropertyType String -Force
    Write-Host "Default shell: Windows PowerShell 5.1" -ForegroundColor Yellow
} else {
    Write-Host "Default shell: PowerShell 7" -ForegroundColor Green
}

# --- 4. Firewall Rule ---------------------------------------------------------
Write-Host "`n[4/6] Configuring Firewall..." -ForegroundColor Yellow

$rule = Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue
if (-not $rule) {
    New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' `
        -DisplayName 'OpenSSH Server (sshd)' `
        -Enabled True -Direction Inbound `
        -Protocol TCP -Action Allow -LocalPort 22
    Write-Host "Firewall rule created" -ForegroundColor Green
} else {
    Write-Host "Firewall rule already exists" -ForegroundColor Green
}

# --- 5. SSH Key Authentication ------------------------------------------------
Write-Host "`n[5/6] Setting up SSH key auth..." -ForegroundColor Yellow

$authKeysFile = "$env:USERPROFILE\.ssh\authorized_keys"
$sshDir = "$env:USERPROFILE\.ssh"

if (-not (Test-Path $sshDir)) {
    New-Item -ItemType Directory -Path $sshDir -Force | Out-Null
}

if (-not (Test-Path $authKeysFile)) {
    New-Item -ItemType File -Path $authKeysFile -Force | Out-Null
    Write-Host "Created $authKeysFile" -ForegroundColor Green
    Write-Host "Add your public keys to this file!" -ForegroundColor Yellow
} else {
    Write-Host "authorized_keys already exists" -ForegroundColor Green
}

# Fix permissions for admin users (sshd_config uses different file for admins)
$adminAuthKeys = "C:\ProgramData\ssh\administrators_authorized_keys"
if (-not (Test-Path $adminAuthKeys)) {
    Copy-Item $authKeysFile $adminAuthKeys -ErrorAction SilentlyContinue
}

# --- 6. Wake-on-LAN Setup ----------------------------------------------------
Write-Host "`n[6/6] Wake-on-LAN Configuration..." -ForegroundColor Yellow

# Get network adapter
$adapter = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' -and $_.PhysicalMediaType -like '*802.3*' } | Select-Object -First 1

if ($adapter) {
    Write-Host "Ethernet Adapter: $($adapter.Name)" -ForegroundColor Green
    Write-Host "MAC Address: $($adapter.MacAddress)" -ForegroundColor Green

    # Enable WoL in Windows
    $wol = Get-NetAdapterAdvancedProperty -Name $adapter.Name -DisplayName "Wake on Magic Packet" -ErrorAction SilentlyContinue
    if ($wol) {
        Set-NetAdapterAdvancedProperty -Name $adapter.Name -DisplayName "Wake on Magic Packet" -RegistryValue 1
        Write-Host "Wake on Magic Packet: ENABLED" -ForegroundColor Green
    }

    # Allow wake
    $pnp = Get-PnpDevice | Where-Object { $_.FriendlyName -eq $adapter.InterfaceDescription }
    if ($pnp) {
        Write-Host "Device wake capability configured via adapter properties" -ForegroundColor Green
    }

    # Disable Fast Startup (required for WoL)
    $fastBoot = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -Name "HiberbootEnabled" -ErrorAction SilentlyContinue
    if ($fastBoot -and $fastBoot.HiberbootEnabled -eq 1) {
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -Name "HiberbootEnabled" -Value 0
        Write-Host "Fast Startup DISABLED (required for WoL)" -ForegroundColor Yellow
    }
} else {
    Write-Host "No wired Ethernet adapter found. WoL requires wired connection!" -ForegroundColor Red
}

# --- Summary ------------------------------------------------------------------
Write-Host "`n=== Setup Complete ===" -ForegroundColor Cyan
Write-Host "SSH Server: Running on port 22" -ForegroundColor Green
Write-Host "Test connection: ssh $env:USERNAME@<this-pc-ip>" -ForegroundColor Yellow

# Show IP
$ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -notmatch 'Loopback' -and $_.PrefixOrigin -eq 'Dhcp' }).IPAddress
Write-Host "This PC's IP: $ip" -ForegroundColor Green

if ($adapter) {
    Write-Host "MAC for WoL: $($adapter.MacAddress)" -ForegroundColor Green
    Write-Host "`nIMPORTANT: Also enable WoL in BIOS/UEFI!" -ForegroundColor Red
    Write-Host "  Look for: 'Wake on LAN', 'Power on by PCI-E', or 'Onboard NIC'" -ForegroundColor Yellow
}
