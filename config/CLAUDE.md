# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Environment

- **Platform:** Android (Samsung Galaxy Note) running Termux
- **Shell:** Bash
- **Language preference:** German (user communicates in German)
- **User:** Erik (GitHub: Wittmann1988, email: erikerdmann.ee@gmail.com)
- **Permission mode:** yolo (no confirmation prompts)

## Kali Linux / Proxmark3 Remote Access

The primary workflow is controlling a **Proxmark3 RFID tool** via SSH to a Kali Linux (WSL2) instance on the user's laptop.

### SSH Connection
- **Config:** `~/.ssh/config` with host alias `kali`
- **Host:** `192.168.50.99` (Samsung-Note), User: `erik`
- **Key:** `~/.ssh/id_ed25519` (passwordless auth configured)
- **Password (if needed):** `0852`
- **WSL2 networking:** NAT mode — may require Windows `netsh interface portproxy` for port forwarding
- **WSL2 internal IP:** `172.24.180.232` (can change on restart)
- **Auto-reconnect script:** `~/connect-kali.sh`

### Proxmark3
- **Device:** `/dev/pm3-0` (also `/dev/ttyACM0`)
- **Firmware:** Iceman fork v4.21128, PM3 Generic
- **Client path on Kali:** `/usr/local/bin/proxmark3`
- **Run commands:** `ssh kali "proxmark3 /dev/pm3-0 -c '<command>'"`
- **Local config:** `~/.proxmark3/preferences.json`
- **NfcTools data:** `/storage/emulated/0/NfcTools/` (dumps, keys, Chameleon slots)
- **Default keys file:** `/storage/emulated/0/NfcTools/keyFile/default_keys.txt`

### Common Proxmark3 Commands
```bash
ssh kali "proxmark3 /dev/pm3-0 -c 'hf search'"        # Scan HF cards
ssh kali "proxmark3 /dev/pm3-0 -c 'lf search'"        # Scan LF cards
ssh kali "proxmark3 /dev/pm3-0 -c 'hf mf chk *1 ? d'" # Check MIFARE keys
ssh kali "proxmark3 /dev/pm3-0 -c 'hf mf darkside'"   # Darkside attack
ssh kali "proxmark3 /dev/pm3-0 -c 'hw version'"       # Hardware info
```

### WSL2 Port Forwarding (when SSH fails)
If SSH times out but ping works, WSL2 port forwarding may need reconfiguring. In Windows PowerShell (Admin):
```powershell
netsh interface portproxy add v4tov4 listenport=22 listenaddress=0.0.0.0 connectport=22 connectaddress=<WSL-IP>
```
Get WSL IP with: `wsl -- ip addr show eth0 | grep "inet "`

## Termux Specifics

- **Glob/Grep tools may fail** — ripgrep binary missing for arm64-android. Use Bash `find`/`grep` as fallback.
- **TMPDIR:** Set `CLAUDE_CODE_TMPDIR=$PREFIX/tmp` before launching Claude Code
- **proot-distro:** Debian installed (`proot-distro login debian`)
- **Proxmark3 client also available in Debian proot** at `/data/data/com.termux/files/usr/bin/proxmark3`
- **Ollama** installed locally (`~/.ollama/`)
- **sshpass** installed for automated password auth

## Projects

- **HackAI** (`~/HackAI/`) — AI-Powered Penetration Testing Assistant (Next.js, Convex, forked from hackerai-tech/hackerai)
- **MCP server:** sequential-thinking at `~/downloads/mcp-sequential-thinking/`

## GitHub (Wittmann1988)
Key repos: hackerai, MicroThinker, Research, bettercap, HackBot, LocalAI
