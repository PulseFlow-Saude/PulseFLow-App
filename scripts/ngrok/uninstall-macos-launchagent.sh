#!/usr/bin/env bash
set -euo pipefail

DEST="$HOME/Library/LaunchAgents/com.oryonhealth.ngrok.plist"
launchctl bootout "gui/$(id -u)" "$DEST" 2>/dev/null || true
rm -f "$DEST"
echo "LaunchAgent removido."
