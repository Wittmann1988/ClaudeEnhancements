#!/usr/bin/env bash
# ============================================================================
# mesh - Home Network Device Mesh Manager
# ============================================================================
# Central CLI tool to manage SSH connections, Wake-on-LAN, file transfers,
# and multi-device command execution across a home network.
#
# Usage: mesh <command> [options]
# ============================================================================

set -euo pipefail

# --- Configuration -----------------------------------------------------------
MESH_CONFIG_DIR="${HOME}/.config/mesh-network"
MESH_CONFIG="${MESH_CONFIG_DIR}/devices.conf"
MESH_LOG="${MESH_CONFIG_DIR}/mesh.log"
MESH_KEYS_DIR="${HOME}/.ssh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# --- Init config if missing --------------------------------------------------
init_config() {
    mkdir -p "$MESH_CONFIG_DIR"
    if [[ ! -f "$MESH_CONFIG" ]]; then
        cat > "$MESH_CONFIG" << 'CONF'
# ============================================================================
# Mesh Network Device Configuration
# ============================================================================
# Format: NAME|TYPE|IP|MAC|SSH_USER|SSH_PORT|SSH_KEY|WOL_CAPABLE|DESCRIPTION
# TYPE: router, desktop, laptop, tablet, server, vm
# WOL_CAPABLE: yes/no
# Lines starting with # are comments
# ============================================================================

# --- Router (Asuswrt-Merlin) ---
router|router|192.168.50.1||admin|22|~/.ssh/id_ed25519|no|ASUS Router (Merlin)

# --- Big Gaming/Work PC (Windows) ---
gaming-pc|desktop|192.168.50.100|AA:BB:CC:DD:EE:FF|erik|22|~/.ssh/id_ed25519|yes|Gaming/Work PC (Windows 11)

# --- Laptop with WSL2/Kali ---
laptop|laptop|192.168.50.99||erik|22|~/.ssh/id_ed25519|yes|Laptop (WSL2/Kali)

# --- Kali VM (WSL2 inside laptop) ---
kali|vm|192.168.50.99||erik|22|~/.ssh/id_ed25519|no|Kali Linux (WSL2)

# --- Android Tablet (Termux - this device) ---
tablet|tablet|192.168.50.50||u0_a0|8022||no|Android Tablet (Termux)

CONF
        echo -e "${GREEN}Config created at: ${MESH_CONFIG}${NC}"
        echo -e "${YELLOW}Edit it with your actual IPs and MACs!${NC}"
    fi
}

# --- Logging ------------------------------------------------------------------
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$MESH_LOG"
}

# --- Parse device config ------------------------------------------------------
get_device() {
    local name="$1"
    grep -v '^#' "$MESH_CONFIG" | grep -v '^$' | grep "^${name}|" | head -1
}

get_all_devices() {
    grep -v '^#' "$MESH_CONFIG" | grep -v '^$'
}

get_field() {
    echo "$1" | cut -d'|' -f"$2"
}

# --- Status check (ping) -----------------------------------------------------
check_online() {
    local ip="$1"
    if ping -c 1 -W 1 "$ip" &>/dev/null; then
        echo "online"
    else
        echo "offline"
    fi
}

# --- Commands -----------------------------------------------------------------

cmd_status() {
    echo -e "\n${BOLD}${CYAN}=== Mesh Network Status ===${NC}\n"
    printf "${BOLD}%-14s %-8s %-16s %-18s %-8s %-6s %s${NC}\n" \
        "NAME" "TYPE" "IP" "MAC" "STATUS" "WOL" "DESCRIPTION"
    echo "--------------------------------------------------------------------------------------------"

    while IFS= read -r line; do
        local name=$(get_field "$line" 1)
        local type=$(get_field "$line" 2)
        local ip=$(get_field "$line" 3)
        local mac=$(get_field "$line" 4)
        local wol=$(get_field "$line" 8)
        local desc=$(get_field "$line" 9)

        local status=$(check_online "$ip")
        local status_color="${RED}"
        [[ "$status" == "online" ]] && status_color="${GREEN}"

        printf "%-14s %-8s %-16s %-18s ${status_color}%-8s${NC} %-6s %s\n" \
            "$name" "$type" "$ip" "${mac:---}" "$status" "$wol" "$desc"
    done <<< "$(get_all_devices)"
    echo ""
}

cmd_wake() {
    local name="${1:-}"
    if [[ -z "$name" ]]; then
        echo -e "${RED}Usage: mesh wake <device-name>${NC}"
        return 1
    fi

    local device=$(get_device "$name")
    if [[ -z "$device" ]]; then
        echo -e "${RED}Device '$name' not found in config${NC}"
        return 1
    fi

    local mac=$(get_field "$device" 4)
    local wol=$(get_field "$device" 8)
    local ip=$(get_field "$device" 3)

    if [[ "$wol" != "yes" ]]; then
        echo -e "${RED}Device '$name' is not WoL-capable${NC}"
        return 1
    fi

    if [[ -z "$mac" ]]; then
        echo -e "${RED}No MAC address configured for '$name'${NC}"
        return 1
    fi

    echo -e "${YELLOW}Sending WoL magic packet to ${name} (${mac})...${NC}"
    log "WoL: Waking $name ($mac)"

    # Try multiple methods
    local sent=false

    # Method 1: wakeonlan (Termux/Linux)
    if command -v wakeonlan &>/dev/null; then
        wakeonlan "$mac" && sent=true
    fi

    # Method 2: etherwake (Linux/Router)
    if ! $sent && command -v etherwake &>/dev/null; then
        etherwake -b "$mac" && sent=true
    fi

    # Method 3: wol via python
    if ! $sent && command -v python3 &>/dev/null; then
        python3 -c "
import socket, struct
mac = '$mac'.replace(':','').replace('-','')
data = b'\\xff' * 6 + bytes.fromhex(mac) * 16
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
sock.sendto(data, ('255.255.255.255', 9))
sock.close()
print('Magic packet sent via Python')
" && sent=true
    fi

    # Method 4: Via router SSH
    if ! $sent; then
        local router=$(get_device "router")
        if [[ -n "$router" ]]; then
            local rip=$(get_field "$router" 3)
            local ruser=$(get_field "$router" 5)
            local rport=$(get_field "$router" 6)
            local rkey=$(get_field "$router" 7)
            rkey="${rkey/#\~/$HOME}"
            echo -e "${BLUE}Sending WoL via router...${NC}"
            ssh -p "$rport" -i "$rkey" -o ConnectTimeout=5 "${ruser}@${rip}" \
                "ether-wake -i br0 -b $mac" 2>/dev/null && sent=true
        fi
    fi

    if $sent; then
        echo -e "${GREEN}Magic packet sent! Waiting for device to boot...${NC}"
        # Wait and check
        for i in $(seq 1 30); do
            sleep 2
            if [[ "$(check_online "$ip")" == "online" ]]; then
                echo -e "${GREEN}${name} is now ONLINE!${NC}"
                log "WoL: $name came online after ${i}x2 seconds"
                return 0
            fi
            echo -n "."
        done
        echo ""
        echo -e "${YELLOW}Device not responding yet. It may still be booting.${NC}"
    else
        echo -e "${RED}No WoL method available. Install wakeonlan or etherwake.${NC}"
        return 1
    fi
}

cmd_ssh() {
    local name="${1:-}"
    shift 2>/dev/null || true

    if [[ -z "$name" ]]; then
        echo -e "${RED}Usage: mesh ssh <device-name> [command]${NC}"
        return 1
    fi

    local device=$(get_device "$name")
    if [[ -z "$device" ]]; then
        echo -e "${RED}Device '$name' not found${NC}"
        return 1
    fi

    local ip=$(get_field "$device" 3)
    local user=$(get_field "$device" 5)
    local port=$(get_field "$device" 6)
    local key=$(get_field "$device" 7)
    key="${key/#\~/$HOME}"

    local ssh_opts="-o ConnectTimeout=10 -o StrictHostKeyChecking=accept-new"
    [[ -n "$port" ]] && ssh_opts="$ssh_opts -p $port"
    [[ -n "$key" && -f "$key" ]] && ssh_opts="$ssh_opts -i $key"

    if [[ $# -gt 0 ]]; then
        # Execute command
        log "SSH exec on $name: $*"
        ssh $ssh_opts "${user}@${ip}" "$@"
    else
        # Interactive session
        log "SSH interactive to $name"
        ssh $ssh_opts "${user}@${ip}"
    fi
}

cmd_exec() {
    # Execute command on multiple devices
    local targets="${1:-}"
    shift 2>/dev/null || true
    local cmd="$*"

    if [[ -z "$targets" || -z "$cmd" ]]; then
        echo -e "${RED}Usage: mesh exec <device1,device2,...|all> <command>${NC}"
        echo -e "${YELLOW}Example: mesh exec laptop,kali 'uname -a'${NC}"
        echo -e "${YELLOW}Example: mesh exec all 'hostname'${NC}"
        return 1
    fi

    local devices=()
    if [[ "$targets" == "all" ]]; then
        while IFS= read -r line; do
            devices+=("$(get_field "$line" 1)")
        done <<< "$(get_all_devices)"
    else
        IFS=',' read -ra devices <<< "$targets"
    fi

    echo -e "\n${BOLD}${CYAN}=== Executing on ${#devices[@]} device(s) ===${NC}\n"
    log "Multi-exec on ${targets}: $cmd"

    for name in "${devices[@]}"; do
        local device=$(get_device "$name")
        if [[ -z "$device" ]]; then
            echo -e "${RED}[$name] Device not found${NC}"
            continue
        fi

        local ip=$(get_field "$device" 3)
        if [[ "$(check_online "$ip")" != "online" ]]; then
            echo -e "${RED}[$name] OFFLINE - skipping${NC}"
            continue
        fi

        echo -e "${BOLD}${BLUE}--- [$name] ---${NC}"
        cmd_ssh "$name" "$cmd" 2>&1 || echo -e "${RED}[$name] Command failed${NC}"
        echo ""
    done
}

cmd_scp() {
    local direction="${1:-}"
    local src_dev="${2:-}"
    local src_path="${3:-}"
    local dst_dev="${4:-}"
    local dst_path="${5:-}"

    if [[ -z "$direction" || -z "$src_dev" || -z "$src_path" ]]; then
        echo -e "${RED}Usage: mesh scp <push|pull|transfer> <args>${NC}"
        echo ""
        echo -e "  ${YELLOW}mesh scp push <device> <local-path> <remote-path>${NC}"
        echo -e "  ${YELLOW}mesh scp pull <device> <remote-path> <local-path>${NC}"
        echo -e "  ${YELLOW}mesh scp transfer <src-device> <src-path> <dst-device> <dst-path>${NC}"
        return 1
    fi

    local build_scp_target() {
        local dev="$1"
        local path="$2"
        local device=$(get_device "$dev")
        local ip=$(get_field "$device" 3)
        local user=$(get_field "$device" 5)
        local port=$(get_field "$device" 6)
        local key=$(get_field "$device" 7)
        key="${key/#\~/$HOME}"
        echo "${user}@${ip}:${path}"
    }

    local get_scp_opts() {
        local dev="$1"
        local device=$(get_device "$dev")
        local port=$(get_field "$device" 6)
        local key=$(get_field "$device" 7)
        key="${key/#\~/$HOME}"
        local opts="-o StrictHostKeyChecking=accept-new"
        [[ -n "$port" ]] && opts="$opts -P $port"
        [[ -n "$key" && -f "$key" ]] && opts="$opts -i $key"
        echo "$opts"
    }

    case "$direction" in
        push)
            local remote_path="${dst_dev:-$src_path}"  # dst_dev is actually remote_path here
            local device_name="$src_dev"
            local local_path="$src_path"
            local opts=$(get_scp_opts "$device_name")
            local target=$(build_scp_target "$device_name" "$remote_path")
            echo -e "${BLUE}Pushing ${local_path} -> ${device_name}:${remote_path}${NC}"
            log "SCP push: $local_path -> $device_name:$remote_path"
            scp $opts "$local_path" "$target"
            ;;
        pull)
            local local_dest="${dst_dev:-./}"  # dst_dev is actually local_path here
            local device_name="$src_dev"
            local remote_path="$src_path"
            local opts=$(get_scp_opts "$device_name")
            local target=$(build_scp_target "$device_name" "$remote_path")
            echo -e "${BLUE}Pulling ${device_name}:${remote_path} -> ${local_dest}${NC}"
            log "SCP pull: $device_name:$remote_path -> $local_dest"
            scp $opts "$target" "$local_dest"
            ;;
        transfer)
            echo -e "${BLUE}Transferring via local relay: ${src_dev}:${src_path} -> ${dst_dev}:${dst_path}${NC}"
            log "SCP transfer: $src_dev:$src_path -> $dst_dev:$dst_path"
            local tmp="/tmp/mesh_transfer_$(date +%s)"
            mkdir -p "$tmp"
            local src_opts=$(get_scp_opts "$src_dev")
            local src_target=$(build_scp_target "$src_dev" "$src_path")
            scp $src_opts "$src_target" "$tmp/"
            local filename=$(basename "$src_path")
            local dst_opts=$(get_scp_opts "$dst_dev")
            local dst_target=$(build_scp_target "$dst_dev" "$dst_path")
            scp $dst_opts "$tmp/$filename" "$dst_target"
            rm -rf "$tmp"
            echo -e "${GREEN}Transfer complete${NC}"
            ;;
        *)
            echo -e "${RED}Unknown direction: $direction (use push/pull/transfer)${NC}"
            return 1
            ;;
    esac
}

cmd_tunnel() {
    local action="${1:-}"
    local name="${2:-}"
    local local_port="${3:-}"
    local remote_port="${4:-}"

    if [[ -z "$action" || -z "$name" ]]; then
        echo -e "${RED}Usage: mesh tunnel <open|reverse|list|close> <device> [local-port] [remote-port]${NC}"
        echo ""
        echo -e "  ${YELLOW}mesh tunnel open laptop 8080 80${NC}       - Forward local:8080 -> laptop:80"
        echo -e "  ${YELLOW}mesh tunnel reverse laptop 2222 22${NC}    - Reverse: laptop:2222 -> local:22"
        echo -e "  ${YELLOW}mesh tunnel list${NC}                       - Show active tunnels"
        echo -e "  ${YELLOW}mesh tunnel close <pid>${NC}               - Kill tunnel by PID"
        return 1
    fi

    case "$action" in
        open)
            local device=$(get_device "$name")
            local ip=$(get_field "$device" 3)
            local user=$(get_field "$device" 5)
            local port=$(get_field "$device" 6)
            local key=$(get_field "$device" 7)
            key="${key/#\~/$HOME}"

            local ssh_opts="-o ConnectTimeout=10 -o ServerAliveInterval=30 -o ServerAliveCountMax=3"
            [[ -n "$port" ]] && ssh_opts="$ssh_opts -p $port"
            [[ -n "$key" && -f "$key" ]] && ssh_opts="$ssh_opts -i $key"

            echo -e "${BLUE}Opening tunnel: localhost:${local_port} -> ${name}:${remote_port}${NC}"

            if command -v autossh &>/dev/null; then
                autossh -M 0 -f -N -L "${local_port}:localhost:${remote_port}" \
                    $ssh_opts "${user}@${ip}"
            else
                ssh -f -N -L "${local_port}:localhost:${remote_port}" \
                    $ssh_opts "${user}@${ip}"
            fi
            echo -e "${GREEN}Tunnel established${NC}"
            log "Tunnel open: localhost:$local_port -> $name:$remote_port"
            ;;
        reverse)
            local device=$(get_device "$name")
            local ip=$(get_field "$device" 3)
            local user=$(get_field "$device" 5)
            local port=$(get_field "$device" 6)
            local key=$(get_field "$device" 7)
            key="${key/#\~/$HOME}"

            local ssh_opts="-o ConnectTimeout=10 -o ServerAliveInterval=30 -o ServerAliveCountMax=3"
            [[ -n "$port" ]] && ssh_opts="$ssh_opts -p $port"
            [[ -n "$key" && -f "$key" ]] && ssh_opts="$ssh_opts -i $key"

            echo -e "${BLUE}Opening reverse tunnel: ${name}:${local_port} -> localhost:${remote_port}${NC}"

            if command -v autossh &>/dev/null; then
                autossh -M 0 -f -N -R "${local_port}:localhost:${remote_port}" \
                    $ssh_opts "${user}@${ip}"
            else
                ssh -f -N -R "${local_port}:localhost:${remote_port}" \
                    $ssh_opts "${user}@${ip}"
            fi
            echo -e "${GREEN}Reverse tunnel established${NC}"
            log "Reverse tunnel: $name:$local_port -> localhost:$remote_port"
            ;;
        list)
            echo -e "\n${BOLD}${CYAN}=== Active SSH Tunnels ===${NC}\n"
            ps aux 2>/dev/null | grep '[s]sh.*-[NL]\|[s]sh.*-[NR]\|[a]utossh' | \
                awk '{printf "PID %-8s %s\n", $2, substr($0, index($0,$11))}' || \
            ps 2>/dev/null | grep '[s]sh.*-[NL]\|[s]sh.*-[NR]\|[a]utossh' || \
                echo "No active tunnels found"
            echo ""
            ;;
        close)
            if [[ -n "$name" ]]; then
                kill "$name" 2>/dev/null && echo -e "${GREEN}Tunnel (PID $name) closed${NC}" || \
                    echo -e "${RED}Could not kill PID $name${NC}"
            fi
            ;;
    esac
}

cmd_config() {
    local action="${1:-edit}"
    case "$action" in
        edit)
            ${EDITOR:-vi} "$MESH_CONFIG"
            ;;
        show)
            cat "$MESH_CONFIG"
            ;;
        path)
            echo "$MESH_CONFIG"
            ;;
        *)
            echo -e "${RED}Usage: mesh config <edit|show|path>${NC}"
            ;;
    esac
}

cmd_setup_keys() {
    echo -e "\n${BOLD}${CYAN}=== SSH Key Distribution ===${NC}\n"
    local pubkey="${MESH_KEYS_DIR}/id_ed25519.pub"

    if [[ ! -f "$pubkey" ]]; then
        echo -e "${YELLOW}Generating SSH key pair...${NC}"
        ssh-keygen -t ed25519 -f "${MESH_KEYS_DIR}/id_ed25519" -N "" -C "mesh@$(hostname)"
    fi

    echo -e "${GREEN}Public key: $(cat "$pubkey")${NC}\n"

    while IFS= read -r line; do
        local name=$(get_field "$line" 1)
        local ip=$(get_field "$line" 3)
        local user=$(get_field "$line" 5)
        local port=$(get_field "$line" 6)
        local type=$(get_field "$line" 2)

        # Skip self (tablet)
        [[ "$type" == "tablet" ]] && continue

        echo -n "Copy key to ${name} (${user}@${ip})? [y/N] "
        read -r answer
        if [[ "$answer" =~ ^[yYjJ] ]]; then
            local port_opt=""
            [[ -n "$port" ]] && port_opt="-p $port"
            ssh-copy-id $port_opt "${user}@${ip}" 2>/dev/null || \
                echo -e "${RED}Failed to copy key to ${name}${NC}"
        fi
    done <<< "$(get_all_devices)"
}

cmd_help() {
    cat << 'HELP'

  mesh - Home Network Device Mesh Manager

  COMMANDS:
    status                    Show all devices with online/offline status
    wake <device>             Send Wake-on-LAN packet to device
    ssh <device> [cmd]        SSH into device or run command
    exec <devs|all> <cmd>     Run command on multiple devices
    scp push <dev> <l> <r>    Push local file to device
    scp pull <dev> <r> <l>    Pull file from device
    scp transfer <s> <sp> <d> <dp>  Transfer between devices
    tunnel open <dev> <lp> <rp>     Open SSH tunnel
    tunnel reverse <dev> <rp> <lp>  Open reverse SSH tunnel
    tunnel list               List active tunnels
    tunnel close <pid>        Close tunnel by PID
    config edit               Edit device configuration
    config show               Show device configuration
    setup-keys                Distribute SSH keys to all devices
    help                      Show this help

  DEVICE CONFIG: ~/.config/mesh-network/devices.conf

  EXAMPLES:
    mesh status
    mesh wake gaming-pc
    mesh ssh laptop
    mesh ssh kali 'proxmark3 /dev/pm3-0 -c "hw version"'
    mesh exec laptop,kali 'uptime'
    mesh exec all 'hostname'
    mesh scp push laptop ./file.txt /tmp/file.txt
    mesh tunnel open laptop 8080 80

HELP
}

# --- Main Dispatch ------------------------------------------------------------
init_config

case "${1:-help}" in
    status)     cmd_status ;;
    wake)       shift; cmd_wake "$@" ;;
    ssh)        shift; cmd_ssh "$@" ;;
    exec)       shift; cmd_exec "$@" ;;
    scp)        shift; cmd_scp "$@" ;;
    tunnel)     shift; cmd_tunnel "$@" ;;
    config)     shift; cmd_config "$@" ;;
    setup-keys) cmd_setup_keys ;;
    help|--help|-h) cmd_help ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        cmd_help
        exit 1
        ;;
esac
