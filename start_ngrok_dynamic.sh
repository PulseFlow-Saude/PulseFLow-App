#!/bin/bash

# Script para iniciar o túnel ngrok com domínio dinâmico (não expira)
# Uso: ./start_ngrok_dynamic.sh

echo "🚀 Iniciando túnel ngrok com domínio dinâmico para Oryon Health Backend..."

# Parar qualquer instância anterior do ngrok
echo "🛑 Parando instâncias anteriores do ngrok..."
pkill ngrok 2>/dev/null || true
sleep 2

# Verificar se o authtoken está configurado
if ! ngrok config check >/dev/null 2>&1; then
    echo "⚠️  Authtoken não configurado. Configurando..."
    ngrok config add-authtoken 352CeLjds7JvWw7j8KTVlmD10rWw7j8KTVlmD10rV_3WwSKz34HeHMUcLLzchwL
fi

# Iniciar ngrok com domínio dinâmico (não expira)
echo "✅ Iniciando ngrok na porta 65432 com domínio dinâmico..."
echo "📡 A URL será gerada automaticamente e não expira"
echo ""
echo "⚠️  IMPORTANTE: Após iniciar, copie a URL 'Forwarding' e atualize no arquivo .env:"
echo "   API_BASE_URL=https://sua-url-dinamica.ngrok-free.dev"
echo ""
echo "⚠️  Mantenha este terminal aberto enquanto o ngrok estiver rodando."
echo "   Para parar, pressione Ctrl+C"
echo ""

ngrok http 65432


