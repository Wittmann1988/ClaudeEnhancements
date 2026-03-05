# System Memory

## Environment
- Termux on Android 14 (Samsung, kernel 6.1.134)
- Shell: bash
- Shizuku installed & running (ADB shell level access via `shizuku exec`)
- `termux-shizuku-tools` v4.1 installed (`shizuku` / `shk` command)

## Key Aliases & Scripts
- `elias` -> `CLAUDE_CODE_TMPDIR=$PREFIX/tmp claude --dangerously-skip-permissions` (in ~/.bashrc)
- `ai` -> AI Settings Manager & Launcher (`~/.local/bin/ai`, symlinked in $PREFIX/bin)
  - `ai` / `ai menu` -> Interaktives Einstellungsmenue
  - `ai status` -> Aktuellen Provider/Modell anzeigen
  - `ai provider <id>` / `ai model <id>` -> Schnellwechsel
  - `ai key <provider> <key>` -> API Key setzen
  - `ai start` -> AI mit aktuellen Einstellungen starten
  - Config: `~/.config/ai-manager/settings.json`
  - Default: Anthropic Claude Sonnet 4.6 via Abo
  - Vorkonfigurierte Provider: Anthropic, OpenAI, Google, OpenRouter, Local (Ollama)
- `amc` -> `~/app-manager-control.sh` (App Manager control, symlinked in $PREFIX/bin)
- `sysctl` -> System Manager (`~/.local/bin/sysctl`)
  - `sysctl status` / `sysctl ram` - Systemuebersicht
  - `sysctl freeze` / `sysctl unfreeze` - Bloatware verwalten
  - `sysctl screen-off` / `sysctl screen-on` - RAM + Rechte verwalten
  - `sysctl monitor` - Auto Display-Ueberwachung
  - `sysctl clean` - Aggressives RAM-Cleaning
  - Config: `~/.config/ai-manager/system-manager.json`
- `am-save-token` -> App Manager Server Token speichern
- `~/start-shizuku.sh` -> Manual Shizuku start trigger

## System Management
- 127+ Samsung/Google Bloatware-Apps dauerhaft eingefroren
- Screen-Off Monitor: `~/.termux/boot/01-screen-monitor.sh` (auto-start bei Boot)
  - Screen OFF: Force-Stop nicht-essentieller Apps + Kamera/Mikro/Standort-Rechte entziehen
  - Screen ON: Rechte automatisch wiederherstellen
- RAM: ~12GB total, nach Freeze ~5GB verfuegbar (vorher ~3.7GB)
- App Manager Server: Port 60001, Token in `~/.config/ai-manager/appmanager.json`

## Shizuku Auto-Boot
- Script: `~/.termux/boot/00-shizuku-autostart.sh`
- Method: WRITE_SECURE_SETTINGS enables wireless debugging, nmap scans ports 30000-45000, adb connects, starts Shizuku server
- Phantom process killing disabled: `settings_enable_monitor_phantom_procs false`
- Battery whitelist: com.termux, com.termux.api, com.termux.boot

## Permissions
- All runtime permissions granted to: com.termux, com.termux.api, com.termux.boot, com.termux.tasker, com.termux.x11, net.dinglisch.android.taskerm, io.github.muntashirakon.AppManager.debug, com.smoothie.wirelessDebuggingSwitch, moe.shizuku.privileged.api + others
- AppOps set: MANAGE_EXTERNAL_STORAGE, REQUEST_INSTALL_PACKAGES, RUN_IN_BACKGROUND, RUN_ANY_IN_BACKGROUND, SYSTEM_ALERT_WINDOW

## App Manager (io.github.muntashirakon.AppManager.debug)
- See [app-manager.md](app-manager.md) for full feature reference
- Control via: `amc <command>` or direct `am start` intents
- Automation: Profile triggering via AuthFeatureDemultiplexer (needs auth key from Settings > Privacy)
- Direct system ops available via Shizuku: pm, am, appops, dumpsys

## Kali Linux SSH (WSL2 on Laptop)
- Host alias: `kali` (config in ~/.ssh/config)
- Target: erik@192.168.50.99 (Samsung-Note laptop), password: 0852
- WSL2 NAT mode, internal IP 172.24.180.232 (may change on restart)
- SSH key: ~/.ssh/id_ed25519 (passwordless auth)
- Port forwarding often needed via Windows `netsh interface portproxy`
- Auto-reconnect: ~/connect-kali.sh
- Port issues: if port 22 blocked, use `sudo fuser -k 22/tcp` on laptop

## Proxmark3 (via Kali SSH)
- Device: /dev/pm3-0 on Kali laptop
- Firmware: Iceman v4.21128, PM3 Generic
- Run via: `ssh kali "proxmark3 /dev/pm3-0 -c '<cmd>'"`
- NfcTools data on device: /storage/emulated/0/NfcTools/
- Last card seen: MIFARE DESFire EV2 (SL1), UID 04 22 33 44
- Default keys: /storage/emulated/0/NfcTools/keyFile/default_keys.txt
- Chameleon slots configured (8, all disabled)

## Agent Forge Ecosystem (~/agent-forge/)
- Self-improving AI agent ecosystem, 3 git commits on main
- **lib/ollama.js**: Shared client, auto-fallback Cloud→Local
- **lib/locooperator.js**: XML tool-calling agent for codebase navigation
- **cli.js**: `forge status|health|memory|tasks` (alias in .bashrc)
- **Loop Agent**: Task decomposition, LocoOperator scan, memory decay, GitHub sync
- **Memory**: sql.js (pure WASM SQLite), 15 seed memories, data/memory.db
- **Self-Improve**: Analyzes all projects via shared Ollama client
- **Sidekick MCP**: ~/ollama-sidekick/ (Nemotron-3-Nano 30B Cloud)
- Config: ~/.mcp.json (registered as MCP server)
- Plugin: ~/.claude/plugins/ollama-sidekick/ (always-active orchestration)
- Local default model: frob/locooperator:4b-q4_K_M (wenn verfuegbar)
- Fallback model: huihui_ai/orchestrator-abliterated (5GB, langsam auf Handy)
- **Blocker**: OLLAMA_API_KEY fehlt (Cloud), GitHub auth fehlt (Push)

## Memory Framework Research (Maerz 2026)
- Best for Termux: **sqlite-vec + custom code** (9/10)
- Upgrade path: **Mem0** with Ollama embeddings (7/10)
- Letta/MemGPT: Too heavy for Android (3/10)
- ChromaDB: onnxruntime blocker on Android (4/10)

## LocoOperator-4B (Local Loop Agent)
- Model: frob/locooperator:4b-q4_K_M (2.5GB, Q4)
- Pull: `ollama pull frob/locooperator:4b-q4_K_M`
- Context: 16K training, 50K deployment, 256K max
- Tool format: `<tool_call>{"name":"Tool","arguments":{...}}</tool_call>`
- Tools: Read, Write, Edit, Grep, Glob, Bash, Task
- 100% JSON validity, surpasses teacher model
- Use as local codebase navigator + memory manager

## Installed Termux Packages
- android-tools, nmap, termux-api, termux-shizuku-tools, termux-gui-package, sshpass
