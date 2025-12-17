# 🔧 Como Reiniciar o Túnel Ngrok

## ⚠️ Problema: Túnel ngrok está offline

Se o túnel ngrok está offline, siga estes passos:

## 📋 Passos para Resolver

### 1️⃣ **Verificar se o backend está rodando**

Primeiro, certifique-se de que o **backend está rodando na porta 65432**:

```bash
# Verificar se algo está rodando na porta 65432
lsof -i :65432
```

Se nada estiver rodando, você precisa iniciar o backend primeiro.

### 2️⃣ **Reiniciar o ngrok**

Você tem 2 opções:

#### **Opção A: Usar o script automático (RECOMENDADO) ⭐**

```bash
cd /Users/henriqueribeiro/Documents/GitHub/PulseFlow-APP
./start_ngrok.sh
```

Este script vai:
- ✅ Parar qualquer instância anterior do ngrok
- ✅ Verificar se o authtoken está configurado
- ✅ Iniciar o ngrok na porta 65432
- ✅ Usar o domínio fixo: `intractable-nonimplemental-garnet.ngrok-free.dev`

#### **Opção B: Comando manual**

Se preferir fazer manualmente:

```bash
# 1. Parar processos antigos do ngrok
pkill ngrok

# 2. Aguardar 2 segundos
sleep 2

# 3. Iniciar o ngrok
ngrok http 65432 --domain=intractable-nonimplemental-garnet.ngrok-free.dev
```

### 3️⃣ **Verificar se o ngrok está funcionando**

#### Verificar se o processo está rodando:
```bash
ps aux | grep ngrok | grep -v grep
```

Se aparecer algo, o ngrok está rodando! ✅

#### Verificar a URL do túnel:
```bash
curl http://localhost:4040/api/tunnels | grep public_url
```

#### Interface web do ngrok:
Abra no navegador: **http://localhost:4040**

Você verá uma página com informações sobre o túnel ativo.

### 4️⃣ **Importante**

⚠️ **Mantenha o terminal do ngrok aberto** enquanto estiver desenvolvendo!

Se você fechar o terminal, o ngrok para de funcionar.

---

## 🐛 Problemas Comuns e Soluções

### ❌ Erro: "backend não está respondendo"

**Problema**: O backend não está rodando na porta 65432.

**Solução**: Inicie o backend primeiro, depois inicie o ngrok.

---

### ❌ Erro: "domain already in use"

**Problema**: O domínio já está em uso (outro processo ngrok está rodando).

**Solução**:
```bash
# Parar todos os processos ngrok
pkill ngrok

# Aguardar alguns segundos
sleep 3

# Tentar iniciar novamente
./start_ngrok.sh
```

---

### ❌ Erro: "authtoken invalid"

**Problema**: O token de autenticação do ngrok expirou ou está inválido.

**Solução**: O script já configura automaticamente, mas se precisar:
```bash
ngrok config add-authtoken 352CeLjds7JvWw7j8KTVlmD10rV_3WwSKz34HeHMUcLLzchwL
```

---

### ❌ Erro: "tunnel offline" no app

**Problema**: O túnel caiu ou o backend parou.

**Solução**:
1. Verifique se o backend está rodando: `lsof -i :65432`
2. Reinicie o ngrok: `./start_ngrok.sh`
3. No app, tente novamente

---

## 📱 Verificar no App

Depois de reiniciar o ngrok, no app você deve ver:
- ✅ Conexões funcionando normalmente
- ✅ Sincronização de dados funcionando
- ✅ Sem erros de "túnel offline"

---

## 🔄 Comandos Rápidos

```bash
# Verificar status do ngrok
ps aux | grep ngrok | grep -v grep

# Parar o ngrok
pkill ngrok

# Iniciar o ngrok
cd /Users/henriqueribeiro/Documents/GitHub/PulseFlow-APP && ./start_ngrok.sh

# Ver URL do túnel
curl http://localhost:4040/api/tunnels | grep public_url
```

---

## 📝 Notas

- O domínio fixo do ngrok é: `intractable-nonimplemental-garnet.ngrok-free.dev`
- O backend deve estar na porta: `65432`
- A URL configurada no `.env` é: `API_BASE_URL=https://intractable-nonimplemental-garnet.ngrok-free.dev`

Se precisar alterar a URL, edite o arquivo `.env` na raiz do projeto.



