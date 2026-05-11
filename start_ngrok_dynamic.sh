#!/usr/bin/env bash
# Igual ao start_ngrok.sh, mas destina-se a URL dinâmica: em scripts/ngrok/ngrok.env
# deixe NGROK_DOMAIN comentado. Após cada reinício, confira a nova URL no dashboard ngrok
# e atualize API_BASE_URL no .env do app, se necessário.

cd "$(dirname "$0")"
exec ./scripts/ngrok/watchdog.sh
