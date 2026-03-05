#!/usr/bin/env bash
# ============================================================================
# Termux (Android Tablet) - SSH & Mesh Setup
# Run this ON the tablet in Termux
# ============================================================================

set -euo pipefail

echo "=== Termux Mesh Network Setup ==="

# --- 1. Install required packages --------------------------------------------
echo ""
echo "[1/5] Installing packages..."
pkg update -y
pkg install -y openssh rsync autossh mosh python3 nmap curl jq termux-api

# Python WoL tool
pip install wakeonlan 2>/dev/null || true

echo "Packages installed"

# --- 2. Configure SSH Server --------------------------------------------------
echo ""
echo "[2/5] Configuring Termux SSH Server..."

# Generate host keys if missing
if [ ! -f ~/.ssh/ssh_host_ed25519_key ]; then
    ssh-keygen -t ed25519 -f ~/.ssh/ssh_host_ed25519_key -N ""
fi

# Generate user key pair if missing
if [ ! -f ~/.ssh/id_ed25519 ]; then
    ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N "" -C "mesh@termux"
    echo "Generated SSH key pair"
fi

# Termux sshd runs on port 8022 by default
echo "SSH server port: 8022"
echo "Start with: sshd"
echo "Stop with: pkill sshd"

# --- 3. Setup SSH config for mesh devices -------------------------------------
echo ""
echo "[3/5] Setting up SSH config..."

# Backup existing
[ -f ~/.ssh/config ] && cp ~/.ssh/config ~/.ssh/config.bak

cat > ~/.ssh/config << 'SSHCONFIG'
# === Mesh Network SSH Config ===

# ASUS Router (Merlin)
Host router merlin
    HostName 192.168.50.1
    User admin
    Port 22
    IdentityFile ~/.ssh/id_ed25519
    ServerAliveInterval 30
    ServerAliveCountMax 3

# Gaming/Work PC (Windows)
Host gaming-pc pc windows
    HostName 192.168.50.100
    User erik
    Port 22
    IdentityFile ~/.ssh/id_ed25519
    ServerAliveInterval 30
    ServerAliveCountMax 3

# Laptop (direct)
Host laptop
    HostName 192.168.50.99
    User erik
    Port 22
    IdentityFile ~/.ssh/id_ed25519
    ServerAliveInterval 30
    ServerAliveCountMax 3

# Kali Linux (WSL2 via laptop port forward)
Host kali
    HostName 192.168.50.99
    User erik
    Port 22
    IdentityFile ~/.ssh/id_ed25519
    ServerAliveInterval 30
    ServerAliveCountMax 3

# Wildcard: all mesh hosts
Host router merlin gaming-pc pc windows laptop kali
    StrictHostKeyChecking accept-new
    AddKeysToAgent yes
    ConnectTimeout 10
SSHCONFIG

chmod 600 ~/.ssh/config
echo "SSH config written to ~/.ssh/config"

# --- 4. Install mesh tool ----------------------------------------------------
echo ""
echo "[4/5] Installing mesh CLI tool..."

MESH_DIR="$HOME/repos/ClaudeEnhancements/mesh-network"
MESH_BIN="$PREFIX/bin/mesh"

if [ -f "$MESH_DIR/mesh.sh" ]; then
    ln -sf "$MESH_DIR/mesh.sh" "$MESH_BIN"
    echo "mesh command linked: $MESH_BIN -> $MESH_DIR/mesh.sh"
else
    echo "mesh.sh not found at $MESH_DIR/mesh.sh"
    echo "Clone the repo first or adjust the path"
fi

# --- 5. Auto-start sshd on boot ----------------------------------------------
echo ""
echo "[5/5] Setting up boot autostart..."

mkdir -p ~/.termux/boot

cat > ~/.termux/boot/02-sshd-start.sh << 'BOOT'
#!/data/data/com.termux/files/usr/bin/bash
# Start SSH server on boot
termux-wake-lock
sshd
BOOT

chmod +x ~/.termux/boot/02-sshd-start.sh
echo "sshd auto-start configured"

# --- Summary ------------------------------------------------------------------
echo ""
echo "=== Termux Setup Complete ==="
echo ""
echo "Your public key (copy to other devices):"
cat ~/.ssh/id_ed25519.pub
echo ""
echo "Commands:"
echo "  mesh status      - Show all devices"
echo "  mesh ssh laptop  - SSH to laptop"
echo "  mesh wake pc     - Wake gaming PC"
echo "  sshd             - Start SSH server (port 8022)"
echo ""
echo "Next steps:"
echo "  1. Copy your public key to all other devices"
echo "  2. Edit mesh config: mesh config edit"
echo "  3. Update MAC addresses and IPs in the config"
