#!/usr/bin/env bash
# Uma sessão só (foreground). Ctrl+C para parar — sem loop de watchdog.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -f "$SCRIPT_DIR/ngrok.env" ]]; then
  # shellcheck source=/dev/null
  source "$SCRIPT_DIR/ngrok.env"
fi

PORT="${NGROK_PORT:-65432}"

if ! ngrok config check >/dev/null 2>&1; then
  echo "Configure: ngrok config add-authtoken <token>"
  exit 1
fi

if [[ -n "${NGROK_DOMAIN:-}" ]]; then
  exec ngrok http "$PORT" --domain="$NGROK_DOMAIN"
fi

exec ngrok http "$PORT"
