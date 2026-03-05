#!/bin/sh
# ============================================================================
# Asuswrt-Merlin Router Setup Script
# SSH into router first, then run this or execute commands manually
# ============================================================================

echo "=== Asuswrt-Merlin Mesh Network Setup ==="

# --- 1. Install Entware (if not already) -------------------------------------
echo ""
echo "[1/5] Checking Entware..."
if [ -f /opt/bin/opkg ]; then
    echo "Entware already installed"
else
    echo "Entware not found. Install via amtm or:"
    echo "  1. Format a USB drive as ext4"
    echo "  2. Plug into router"
    echo "  3. Run: amtm"
    echo "  4. Select 'ep' for Entware install"
    echo ""
    echo "Or manual: wget -O /tmp/install.sh http://bin.entware.net/aarch64-k3.10/installer/generic.sh && sh /tmp/install.sh"
    exit 1
fi

# --- 2. Install essential packages -------------------------------------------
echo ""
echo "[2/5] Installing packages..."
opkg update

# SSH tools
opkg install openssh-client openssh-keygen 2>/dev/null
opkg install autossh 2>/dev/null
opkg install sshpass 2>/dev/null

# Terminal multiplexer
opkg install tmux 2>/dev/null
opkg install screen 2>/dev/null

# Network tools
opkg install mosh-server 2>/dev/null
opkg install rsync 2>/dev/null
opkg install curl 2>/dev/null
opkg install wget-ssl 2>/dev/null
opkg install nmap 2>/dev/null
opkg install bind-dig 2>/dev/null

# Utilities
opkg install bash 2>/dev/null
opkg install nano 2>/dev/null
opkg install jq 2>/dev/null
opkg install coreutils-timeout 2>/dev/null

echo "Package installation complete"

# --- 3. Tailscale (via TAILMON) -----------------------------------------------
echo ""
echo "[3/5] Tailscale setup..."
echo "Recommended: Install TAILMON via amtm for managed Tailscale"
echo "  1. SSH into router"
echo "  2. Run: amtm"
echo "  3. Look for TAILMON in the menu"
echo ""
echo "Manual Entware install:"
echo "  opkg install tailscale tailscaled"
echo "  /opt/etc/init.d/S06tailscaled start"
echo "  tailscale up"

# --- 4. WoL script on router -------------------------------------------------
echo ""
echo "[4/5] Setting up WoL helper script..."

cat > /jffs/scripts/wol.sh << 'WOL'
#!/bin/sh
# Wake-on-LAN helper for router
# Usage: /jffs/scripts/wol.sh <device-name|MAC>

# Device registry (edit these)
case "$1" in
    gaming-pc|pc)
        MAC="AA:BB:CC:DD:EE:FF"
        NAME="Gaming PC"
        ;;
    laptop)
        MAC="11:22:33:44:55:66"
        NAME="Laptop"
        ;;
    *)
        # Assume raw MAC address
        MAC="$1"
        NAME="$1"
        ;;
esac

if [ -z "$MAC" ]; then
    echo "Usage: $0 <device-name|MAC-address>"
    echo "Devices: gaming-pc, laptop"
    exit 1
fi

echo "Sending WoL to $NAME ($MAC)..."
/usr/sbin/ether-wake -i br0 -b "$MAC"
echo "Magic packet sent"
WOL

chmod +x /jffs/scripts/wol.sh
echo "WoL script created at /jffs/scripts/wol.sh"

# --- 5. DDNS setup ------------------------------------------------------------
echo ""
echo "[5/5] DDNS Configuration..."
echo "To set up DuckDNS:"
echo "  1. Register at https://www.duckdns.org/"
echo "  2. Create a subdomain"
echo "  3. Copy your token"
echo "  4. Create /jffs/scripts/ddns-start:"

cat << 'DDNS_EXAMPLE'

#!/bin/sh
# /jffs/scripts/ddns-start
# Set DDNS to "Custom" in router web UI

SUBDOMAIN="your-subdomain"
TOKEN="your-duckdns-token"

curl -s "https://www.duckdns.org/update?domains=${SUBDOMAIN}&token=${TOKEN}&ip=" > /dev/null 2>&1

if [ $? -eq 0 ]; then
    /sbin/ddns_custom_updated 1
else
    /sbin/ddns_custom_updated 0
fi

DDNS_EXAMPLE

echo ""
echo "=== Router setup complete ==="
echo "Remember to:"
echo "  1. Enable SSH in Administration > System"
echo "  2. Enable JFFS scripts in Administration > System"
echo "  3. Set DDNS to Custom if using DuckDNS"
echo "  4. Edit MAC addresses in /jffs/scripts/wol.sh"
