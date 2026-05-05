#!/usr/bin/env bash
# Inicia o ngrok com reinício automático (watchdog). Para domínio fixo, copie
# scripts/ngrok/ngrok.env.example → scripts/ngrok/ngrok.env e defina NGROK_DOMAIN.
#
# macOS — arrancar sempre ao iniciar sessão:
#   ./scripts/ngrok/install-macos-launchagent.sh
#
# Não coloque authtoken neste ficheiro; use: ngrok config add-authtoken <token>

cd "$(dirname "$0")"
exec ./scripts/ngrok/watchdog.sh
