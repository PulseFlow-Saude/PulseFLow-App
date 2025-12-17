# 🔧 Solução para ERR_NGROK_3200 - Túnel Ngrok Offline

## ⚠️ Problema
O erro `ERR_NGROK_3200` indica que o domínio fixo do ngrok não está mais ativo ou expirou.

## 🔍 Verificações Iniciais

### 1. Verificar se o backend está rodando
```bash
lsof -i :65432
```

Se nada aparecer, inicie o backend primeiro.

### 2. Verificar status do ngrok
```bash
ps aux | grep ngrok | grep -v grep
curl -s http://localhost:4040/api/tunnels
```

## ✅ Soluções

### **Solução 1: Usar Túnel Dinâmico (Temporário)**

Se o domínio fixo expirou, use um túnel dinâmico:

```bash
# Parar ngrok atual
pkill ngrok

# Iniciar com túnel dinâmico
ngrok http 65432
```

Isso vai gerar uma URL temporária como: `https://abc123.ngrok-free.app`

**⚠️ IMPORTANTE**: Você precisará atualizar a URL no arquivo `.env`:

```env
API_BASE_URL=https://abc123.ngrok-free.app
```

### **Solução 2: Renovar Domínio Fixo no Ngrok**

1. Acesse: https://dashboard.ngrok.com/domains
2. Verifique se o domínio `intractable-nonimplemental-garnet.ngrok-free.dev` ainda está ativo
3. Se expirou, você pode:
   - Renovar o domínio (se tiver plano pago)
   - Criar um novo domínio fixo
   - Usar túnel dinâmico (Solução 1)

### **Solução 3: Verificar Autenticação**

```bash
# Verificar configuração
ngrok config check

# Se necessário, reconfigurar authtoken
ngrok config add-authtoken SEU_AUTHTOKEN_AQUI
```

### **Solução 4: Usar Túnel Local (Desenvolvimento)**

Para desenvolvimento local, você pode usar o IP local:

1. Descubra seu IP local:
```bash
ifconfig | grep "inet " | grep -v 127.0.0.1
```

2. No arquivo `.env`, use:
```env
API_BASE_URL=http://SEU_IP_LOCAL:65432
```

**⚠️ LIMITAÇÃO**: Isso só funciona na mesma rede Wi-Fi.

## 🚀 Passo a Passo Rápido (Túnel Dinâmico)

```bash
# 1. Parar ngrok atual
pkill ngrok

# 2. Iniciar ngrok (sem domínio fixo)
ngrok http 65432

# 3. Copiar a URL que aparece (ex: https://abc123.ngrok-free.app)

# 4. Atualizar .env
# Edite o arquivo .env e altere:
# API_BASE_URL=https://SUA_URL_NOVA_AQUI

# 5. Reiniciar o app Flutter
```

## 📝 Notas

- **Domínios fixos gratuitos**: Podem expirar após um período
- **Túneis dinâmicos**: URLs mudam a cada reinício do ngrok
- **Plano pago**: Permite domínios fixos permanentes

## 🔄 Comandos Úteis

```bash
# Ver processos ngrok
ps aux | grep ngrok | grep -v grep

# Parar ngrok
pkill ngrok

# Ver interface web do ngrok
open http://localhost:4040

# Ver URL do túnel ativo
curl -s http://localhost:4040/api/tunnels | python3 -m json.tool
```

## 💡 Dica

Se você precisa de um domínio fixo permanente, considere:
- Upgrade para plano pago do ngrok
- Usar um serviço alternativo (Cloudflare Tunnel, localtunnel, etc.)
- Configurar um servidor com domínio próprio

