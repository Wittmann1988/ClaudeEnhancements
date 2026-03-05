# Alias fuer Claude mit Termux-Konfiguration
alias elias='CLAUDE_CODE_TMPDIR=$PREFIX/tmp claude --dangerously-skip-permissions'
alias elias-resume='CLAUDE_CODE_TMPDIR=$PREFIX/tmp claude --dangerously-skip-permissions --resume'

# Ollama Cloud API - Key in ~/.bashrc (NICHT hier speichern!)
# export OLLAMA_API_KEY="..." -> siehe ~/.bashrc

# AI Settings & Launcher im PATH
export PATH="$HOME/.local/bin:$PATH"

# Agent Forge CLI
alias forge='cd ~/agent-forge && node cli.js'

# App Manager Server via Shizuku - Token in ~/.config/ai-manager/appmanager.json
# alias manager='...' -> siehe ~/.bashrc
