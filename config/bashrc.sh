# Alias fuer Claude mit Termux-Konfiguration
alias elias='CLAUDE_CODE_TMPDIR=$PREFIX/tmp claude --dangerously-skip-permissions'
alias elias-resume='CLAUDE_CODE_TMPDIR=$PREFIX/tmp claude --dangerously-skip-permissions --resume'

# Ollama Cloud API
export OLLAMA_API_KEY="e8428dd33e03460aafbfe61dfed5c5dd.4uwTIo-_kaY-xi1XQKcZG1Mo"

# AI Settings & Launcher im PATH
export PATH="$HOME/.local/bin:$PATH"

# Agent Forge CLI
alias forge='cd ~/agent-forge && node cli.js'

# App Manager Server via Shizuku
alias manager='shizuku exec sh /storage/emulated/0/Android/data/io.github.muntashirakon.AppManager/cache/run_server.sh 60001 drove-golf-canon-shun-sleet'
