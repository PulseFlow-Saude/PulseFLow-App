#!/usr/bin/env bash
# Instala o watchdog ngrok como LaunchAgent (login do utilizador): inicia ao iniciar sessão e reinicia se morrer.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DEST="$HOME/Library/LaunchAgents/com.oryonhealth.ngrok.plist"
TEMPLATE="$SCRIPT_DIR/com.oryonhealth.ngrok.plist.template"

chmod +x "$SCRIPT_DIR/watchdog.sh" "$SCRIPT_DIR/run-once.sh"

mkdir -p "$HOME/Library/LaunchAgents"
sed "s|__REPO_ROOT__|$REPO_ROOT|g" "$TEMPLATE" > "$DEST"

launchctl bootout "gui/$(id -u)" "$DEST" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$DEST"

echo "LaunchAgent instalado: $DEST"
echo "Logs: $REPO_ROOT/scripts/ngrok/launchd.out.log (e launchd.err.log)"
echo "Parar: launchctl bootout gui/$(id -u) $DEST"
