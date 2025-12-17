# 🚀 Configuração do Ngrok - PulseFlow

## ✅ Status Atual

- **Authtoken configurado**: ✅
- **URL do túnel**: `https://intractable-nonimplemental-garnet.ngrok-free.dev`
- **Porta do backend**: `65432`
- **Arquivo .env**: Configurado corretamente

## 📋 Como Usar

### Iniciar o Ngrok

**Opção 1: Usar o script helper (recomendado)**
```bash
cd /Users/henriqueribeiro/Documents/GitHub/PulseFlow-APP
./start_ngrok.sh
```

**Opção 2: Comando manual**
```bash
ngrok http 65432 --domain=intractable-nonimplemental-garnet.ngrok-free.dev
```

### Parar o Ngrok

```bash
pkill ngrok
```

ou pressione `Ctrl+C` no terminal onde o ngrok está rodando.

## ⚠️ Importante

1. **O backend deve estar rodando** na porta `65432` antes de iniciar o ngrok
2. **Mantenha o terminal do ngrok aberto** enquanto estiver desenvolvendo
3. **Se o túnel cair**, simplesmente execute `./start_ngrok.sh` novamente

## 🔍 Verificar Status

### Ver se o ngrok está rodando:
```bash
ps aux | grep ngrok | grep -v grep
```

### Ver a URL pública do túnel:
```bash
curl http://localhost:4040/api/tunnels | grep public_url
```

### Interface web do ngrok:
Abra no navegador: http://localhost:4040

## 🐛 Troubleshooting

### Erro: "tunnel offline"
- Verifique se o backend está rodando na porta 65432
- Reinicie o ngrok: `./start_ngrok.sh`

### Erro: "domain already in use"
- Pare o ngrok: `pkill ngrok`
- Aguarde alguns segundos e inicie novamente

### Erro: "authtoken invalid"
- O authtoken já está configurado, mas se precisar reconfigurar:
```bash
ngrok config add-authtoken 352CeLjds7JvWw7j8KTVlmD10rV_3WwSKz34HeHMUcLLzchwL
```

## 📝 Configuração no App

O arquivo `.env` já está configurado com:
```env
API_BASE_URL=https://intractable-nonimplemental-garnet.ngrok-free.dev
```

Se precisar alterar, edite o arquivo `.env` na raiz do projeto.


