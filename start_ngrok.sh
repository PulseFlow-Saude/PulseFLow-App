#!/bin/bash

# Script para iniciar o túnel ngrok para o PulseFlow Backend
# Uso: ./start_ngrok.sh

echo "🚀 Iniciando túnel ngrok para PulseFlow Backend..."

# Parar qualquer instância anterior do ngrok
echo "🛑 Parando instâncias anteriores do ngrok..."
pkill ngrok 2>/dev/null || true
sleep 2

# Verificar se o authtoken está configurado
if ! ngrok config check >/dev/null 2>&1; then
    echo "⚠️  Authtoken não configurado. Configurando..."
    ngrok config add-authtoken 352CeLjds7JvWw7j8KTVlmD10rV_3WwSKz34HeHMUcLLzchwL
fi

# Iniciar ngrok com domínio fixo
echo "✅ Iniciando ngrok na porta 65432 com domínio fixo..."
echo "📡 URL: https://intractable-nonimplemental-garnet.ngrok-free.dev"
echo ""
echo "⚠️  Mantenha este terminal aberto enquanto o ngrok estiver rodando."
echo "   Para parar, pressione Ctrl+C"
echo ""

ngrok http 65432 --domain=intractable-nonimplemental-garnet.ngrok-free.dev



