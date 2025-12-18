# Scripts de Build

## Scripts Disponíveis

### `generate_firebase_config.js`
Gera o arquivo `web/firebase-config.js` a partir das variáveis de ambiente do arquivo `.env`.

**Uso manual:**
```bash
node scripts/generate_firebase_config.js
```

### `prepare_build.sh`
Script que prepara o ambiente antes do build, incluindo a geração do `firebase-config.js`.

**Uso:**
```bash
./scripts/prepare_build.sh
```

### `run_with_prepare.sh`
Executa o script de preparação e depois executa o comando Flutter passado como argumento.

**Uso:**
```bash
./scripts/run_with_prepare.sh run
./scripts/run_with_prepare.sh build apk
./scripts/run_with_prepare.sh build web
```

## Execução Automática

O script `generate_firebase_config.js` é executado automaticamente:

- **Android**: Antes de cada build via task Gradle `prepareFirebaseConfig`
- **Manual**: Execute `./scripts/prepare_build.sh` antes de builds manuais

## Nota Importante

O arquivo `web/firebase-config.js` é gerado automaticamente e não deve ser editado manualmente. 
Ele está no `.gitignore` para evitar commits acidentais de chaves.

Se você modificar o arquivo `.env`, execute:
```bash
./scripts/prepare_build.sh
```

Ou simplesmente faça um build do Android que executará automaticamente.

