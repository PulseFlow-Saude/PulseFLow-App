#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "🔧 Preparando build do PulseFlow..."

if [ -f "$PROJECT_DIR/.env" ]; then
    echo "✅ Arquivo .env encontrado"
    
    if command -v node &> /dev/null; then
        echo "📝 Gerando firebase-config.js a partir do .env..."
        node "$SCRIPT_DIR/generate_firebase_config.js"
    else
        echo "⚠️  Node.js não encontrado. Pulando geração de firebase-config.js"
    fi
else
    echo "⚠️  Arquivo .env não encontrado em $PROJECT_DIR"
    echo "   Certifique-se de que o arquivo .env existe antes de fazer o build"
fi

echo "✅ Preparação concluída!"

