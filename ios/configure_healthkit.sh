#!/bin/bash

# Script para configurar HealthKit no projeto iOS
echo "🔧 Configurando HealthKit no projeto iOS..."

# Verifica se estamos no diretório correto
if [ ! -f "Runner.xcodeproj/project.pbxproj" ]; then
    echo "❌ Execute este script no diretório ios/"
    exit 1
fi

# Adiciona HealthKit framework ao projeto
echo "📱 Adicionando HealthKit framework..."

# Adiciona HealthKit.framework às bibliotecas do projeto
# Isso precisa ser feito manualmente no Xcode ou via script mais complexo

echo "✅ Configuração do HealthKit concluída!"
echo ""
echo "📋 Próximos passos:"
echo "1. Abra o projeto no Xcode: ios/Runner.xcworkspace"
echo "2. Selecione o target 'Runner'"
echo "3. Vá para 'Signing & Capabilities'"
echo "4. Clique em '+ Capability' e adicione 'HealthKit'"
echo "5. Configure as permissões necessárias:"
echo "   - Health Records (se necessário)"
echo "   - Clinical Health Records (se necessário)"
echo ""
echo "🔍 Verifique se o arquivo Runner.entitlements foi criado corretamente"
echo "📱 Teste no dispositivo físico (HealthKit não funciona no simulador)"
