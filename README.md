# ClaudeEnhancements

Alle Verbesserungen, Plugins, MCP Server, Gedächtnis und Konfiguration für Claude Code.

## Übersicht

```
ClaudeEnhancements/
├── config/              # Konfigurationsdateien
│   ├── CLAUDE.md        # Projektweite Anweisungen
│   ├── mcp.json         # MCP Server Konfiguration
│   └── bashrc.sh        # Shell-Aliases und Umgebungsvariablen
├── plugins/             # Always-Active Plugins
│   └── ollama-sidekick/ # Nemotron Sidekick Orchestrierung
├── mcp-servers/         # MCP Server
│   └── (ollama-sidekick source in ~/ollama-sidekick/)
├── memory/              # Persistentes Gedächtnis
│   └── MEMORY.md        # Auto-Memory (max 200 Zeilen)
└── self-improve/        # Selbstverbesserungsmechanismus
    └── (in Entwicklung)
```

## Installierte Verbesserungen

### MCP Server
| Server | Pfad | Funktion |
|--------|------|----------|
| **sequential-thinking** | `~/downloads/mcp-sequential-thinking/` | Strukturiertes Denken via Chain-of-Thought |
| **ollama-sidekick** | `~/ollama-sidekick/` | 5 Tools: research, review, analyze, ask, search_repos |

### Always-Active Plugins
| Plugin | Funktion |
|--------|----------|
| **ollama-sidekick** | Orchestrierungs-Regeln: Research-First, Auto-Review, Second Opinion |

### Shell-Aliases
| Alias | Kommando |
|-------|----------|
| `elias` | Claude Code mit Skip-Permissions + TMPDIR |
| `elias-resume` | Claude Code mit Session-Resume |
| `forge` | Agent Forge CLI |
| `ai` | AI Settings Manager |
| `sysctl` | System Manager |
| `amc` | App Manager Control |
| `manager` | App Manager Server via Shizuku |

### Gedächtnis-System
- **Auto-Memory** (`~/.claude/projects/.../memory/MEMORY.md`): Max 200 Zeilen, wird automatisch in den Kontext geladen
- **Topic-Files**: Separate Dateien für Details (app-manager.md etc.)
- **Agent Forge Memory**: SQLite-DB mit 15 Seeds, Decay, Reinforcement

### Selbstverbesserung (geplant)
- Agent Forge Self-Improve Pipeline analysiert alle Projekte
- Nemotron Sidekick gibt Review-Feedback
- LocoOperator scannt Codebases autonom
- Ergebnisse fließen zurück in Memory und Code

## Konfigurationsdetails

### MCP Server Config (`~/.mcp.json`)
```json
{
  "mcpServers": {
    "sequential-thinking": {
      "command": "node",
      "args": ["~/downloads/mcp-sequential-thinking/dist/index.js"]
    },
    "ollama-sidekick": {
      "command": "node",
      "args": ["~/ollama-sidekick/index.js"],
      "env": {
        "OLLAMA_API_KEY": "${OLLAMA_API_KEY}",
        "OLLAMA_MODEL": "nemotron-3-nano:30b",
        "OLLAMA_API_URL": "https://ollama.com/v1",
        "OLLAMA_LOCAL_URL": "http://localhost:11434",
        "OLLAMA_LOCAL_MODEL": "frob/locooperator:4b-q4_K_M"
      }
    }
  }
}
```

### Ollama Sidekick Orchestrierung
5 Regeln für automatische Nutzung:
1. **Research-First**: Vor jeder Implementierung existierende Lösungen suchen
2. **Parallel Research**: Research und Implementierung gleichzeitig
3. **Auto-Review**: Code nach Implementierung reviewen lassen
4. **Second Opinion**: Architektur-Entscheidungen gegenchecken
5. **Delegation**: Subtasks an Sidekick delegieren

### Android/Termux-spezifisch
- `CLAUDE_CODE_TMPDIR=$PREFIX/tmp` (Sandbox-Workaround)
- sql.js statt better-sqlite3 (kein Native Compilation)
- Glob/Grep können fehlschlagen → Bash `find`/`grep` als Fallback
- **Tablet-Regel**: Auf Android-Tablet NUR Cloud-Models, nichts lokal (zu langsam)

## Installation auf neuem Gerät
```bash
# 1. Claude Code installieren
npm install -g @anthropic-ai/claude-code

# 2. MCP Server
cd ~/ollama-sidekick && npm install
cd ~/downloads/mcp-sequential-thinking && npm install

# 3. Config kopieren
cp config/mcp.json ~/.mcp.json
cp config/CLAUDE.md ~/CLAUDE.md

# 4. Plugin installieren
mkdir -p ~/.claude/plugins/
cp -r plugins/ollama-sidekick ~/.claude/plugins/

# 5. Memory einrichten
mkdir -p ~/.claude/projects/.../memory/
cp memory/MEMORY.md ~/.claude/projects/.../memory/

# 6. API Key setzen
export OLLAMA_API_KEY="your-key"
```
