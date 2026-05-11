#!/usr/bin/env bash
# Mantém o ngrok no ar: ao cair ou encerrar, reinicia com backoff exponencial.
# Uso: ./scripts/ngrok/watchdog.sh
# macOS “sempre ligado”: ./scripts/ngrok/install-macos-launchagent.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

if [[ -f "$SCRIPT_DIR/ngrok.env" ]]; then
  # shellcheck source=/dev/null
  source "$SCRIPT_DIR/ngrok.env"
fi

PORT="${NGROK_PORT:-65432}"
MIN_WAIT="${NGROK_RESTART_MIN:-2}"
MAX_WAIT="${NGROK_RESTART_MAX:-120}"

if ! command -v ngrok >/dev/null 2>&1; then
  echo "ngrok não está no PATH. Instale: https://ngrok.com/download"
  exit 1
fi

if ! ngrok config check >/dev/null 2>&1; then
  echo "Configure o authtoken desta máquina (uma vez):"
  echo "  ngrok config add-authtoken <seu_token_em_https://dashboard.ngrok.com/get-started/your-authtoken>"
  exit 1
fi

if [[ -n "${NGROK_DOMAIN:-}" ]]; then
  echo "Domínio fixo: $NGROK_DOMAIN"
else
  echo "Sem NGROK_DOMAIN — URL muda a cada reinício; confira com 'ngrok api tunnels' ou no dashboard."
fi

backoff="$MIN_WAIT"

while true; do
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Iniciando túnel ngrok → localhost:$PORT ..."
  started=$(date +%s)
  set +e
  # Não usar array vazio com "${arr[@]}" sob set -u (bash 3.2 do macOS falha).
  if [[ -n "${NGROK_DOMAIN:-}" ]]; then
    ngrok http "$PORT" --domain="$NGROK_DOMAIN"
  else
    ngrok http "$PORT"
  fi
  exit_code=$?
  set -u
  ended=$(date +%s)
  ran_for=$((ended - started))
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] ngrok encerrou (código $exit_code, ${ran_for}s). Nova tentativa em ${backoff}s."

  # Sessões longas = provável reinício voluntário/manutenção; volta ao backoff baixo.
  if [[ "$ran_for" -ge 120 ]]; then
    backoff="$MIN_WAIT"
  else
    next=$(( backoff * 2 ))
    [[ "$next" -gt "$MAX_WAIT" ]] && next="$MAX_WAIT"
    backoff="$next"
  fi

  sleep "$backoff"
done
