<div align="center">

<img src="assets/images/Pulselogo.png" alt="PulseFlow Logo" width="200"/>

# PulseFlow Mobile

**Sistema de Monitoramento de Saúde e Gerenciamento de Pacientes**

[![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?logo=flutter&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart&logoColor=white)](https://dart.dev/)
[![License](https://img.shields.io/badge/License-Proprietary-red)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey)](https://flutter.dev/)

</div>

---

## Índice

- [Sobre o Projeto](#sobre-o-projeto)
- [Funcionalidades](#funcionalidades)
- [Tecnologias](#tecnologias)
- [Pré-requisitos](#pré-requisitos)
- [Instalação](#instalação)
- [Configuração](#configuração)
- [Segurança](#segurança)
- [Testes](#testes)
- [Troubleshooting](#troubleshooting)
- [Licença](#licença)
- [Suporte](#suporte)

---

## Sobre o Projeto

O **PulseFlow Mobile** é um aplicativo desenvolvido em Flutter que permite aos pacientes gerenciar seus dados de saúde de forma completa e segura. O aplicativo oferece monitoramento em tempo real de diversas condições médicas, registro de eventos clínicos, compartilhamento seguro de informações com profissionais de saúde através do **Pulse Key**, e integração com dispositivos wearables.

### Objetivo

Facilitar o acompanhamento da saúde do paciente, proporcionando uma interface intuitiva para registro de dados médicos, visualização de histórico e compartilhamento seguro de informações com profissionais de saúde autorizados.

---

## Funcionalidades

### Autenticação e Segurança

- Login seguro com autenticação de dois fatores (2FA)
- Recuperação de senha via email
- Armazenamento seguro de credenciais com Flutter Secure Storage
- Pulse Key para compartilhamento seguro e temporário de dados

### Monitoramento de Saúde

| Funcionalidade | Descrição |
|---------------|-----------|
| **Pressão Arterial** | Registro e acompanhamento de medições com gráficos interativos |
| **Diabetes** | Controle de glicemia e registro de eventos relacionados |
| **Enxaqueca** | Registro de crises, sintomas e gatilhos identificados |
| **Crise de Gastrite** | Monitoramento de episódios e sintomas |
| **Ciclo Menstrual** | Acompanhamento completo do ciclo e sintomas relacionados |
| **Dados Hormonais** | Registro de informações hormonais e acompanhamento |

### Gestão de Dados Clínicos

- Registro de eventos clínicos diversos
- Upload e visualização de exames médicos
- Prontuário médico completo e organizado
- Histórico detalhado com gráficos e estatísticas

### Integração com Dispositivos

- Conexão com smartwatch via Bluetooth (Flutter Blue Plus)
- Integração com Health (iOS/Android)
- Sincronização automática de dados de saúde

### Notificações

- Notificações push via Firebase Cloud Messaging
- Notificações locais para lembretes e alertas
- Alertas de eventos importantes e críticos

---

## Tecnologias

### Framework e Linguagem

- **Flutter** 3.0+ - Framework multiplataforma
- **Dart** 3.0+ - Linguagem de programação

### Gerenciamento de Estado e Navegação

- **GetX** 4.6+ - Gerenciamento de estado e navegação

### Backend e Banco de Dados

- **MongoDB** - Banco de dados NoSQL
- **Firebase** - Serviços de backend (Cloud Messaging)

### Bibliotecas Principais

| Biblioteca | Versão | Propósito |
|------------|--------|-----------|
| `get` | 4.6+ | Gerenciamento de estado e navegação |
| `flutter_secure_storage` | 8.0+ | Armazenamento seguro de dados |
| `health` | 13.1+ | Integração com dados de saúde nativos |
| `flutter_blue_plus` | 1.32+ | Conexão Bluetooth com dispositivos |
| `fl_chart` | 0.68+ | Gráficos e visualizações de dados |
| `firebase_messaging` | 14.7+ | Notificações push |
| `image_picker` | 1.0+ | Seleção de imagens |
| `file_picker` | 8.1+ | Seleção de arquivos |

---

## Pré-requisitos

Antes de começar, certifique-se de ter instalado e configurado:

- **Flutter SDK** >= 3.0.0 ([Instalação](https://flutter.dev/docs/get-started/install))
- **Dart SDK** >= 3.0.0 ([Instalação](https://dart.dev/get-dart))
- **Android Studio** ou **Xcode** (para desenvolvimento)
- **Git** ([Instalação](https://git-scm.com/))
- **Backend PulseFlow** em execução (porta 65432)
- **MongoDB** configurado e acessível
- **Firebase** configurado com projeto criado

---

## Instalação

### 1. Clone o repositório

```bash
git clone https://github.com/seu-usuario/PulseFlow-APP.git
cd PulseFlow-APP
```

### 2. Instale as dependências

```bash
flutter pub get
```

### 3. Configure o ambiente

Crie um arquivo `.env` na raiz do projeto com as seguintes variáveis:

```env
# URL da API Backend
API_BASE_URL=http://localhost:65432

# MongoDB Connection String
MONGODB_URI=mongodb://localhost:27017/paciente_app

# JWT Secret Key
JWT_SECRET=sua_chave_secreta_aqui

# Email Configuration (opcional)
EMAIL_USER=seu_email@exemplo.com
EMAIL_PASS=sua_senha_email
```

### 4. Configure o Firebase

#### Android

1. Acesse o [Firebase Console](https://console.firebase.google.com/)
2. Baixe o arquivo `google-services.json`
3. Coloque o arquivo em `android/app/google-services.json`

#### iOS

1. Acesse o [Firebase Console](https://console.firebase.google.com/)
2. Baixe o arquivo `GoogleService-Info.plist`
3. Coloque o arquivo em `ios/Runner/GoogleService-Info.plist`

### 5. Execute o aplicativo

#### Modo Desenvolvimento

```bash
flutter run
```

#### Build de Produção

**Android:**
```bash
flutter build apk --release
```

**iOS:**
```bash
flutter build ios --release
```

---

## Configuração

### Variáveis de Ambiente

O aplicativo utiliza variáveis de ambiente para configuração. Todas as variáveis devem ser definidas no arquivo `.env` na raiz do projeto.

| Variável | Descrição | Exemplo |
|----------|-----------|---------|
| `API_BASE_URL` | URL base da API backend | `http://localhost:65432` |
| `MONGODB_URI` | URI de conexão MongoDB | `mongodb://localhost:27017/paciente_app` |
| `JWT_SECRET` | Chave secreta para tokens JWT | `sua_chave_secreta` |
| `EMAIL_USER` | Usuário do email (opcional) | `seu_email@exemplo.com` |
| `EMAIL_PASS` | Senha do email (opcional) | `sua_senha` |

### Permissões

#### Android

Adicione as seguintes permissões em `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.BLUETOOTH"/>
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
```

#### iOS

Adicione as seguintes descrições em `ios/Runner/Info.plist`:

```xml
<key>NSHealthShareUsageDescription</key>
<string>Precisamos acessar seus dados de saúde para monitoramento</string>
<key>NSHealthUpdateUsageDescription</key>
<string>Precisamos atualizar seus dados de saúde</string>
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Precisamos do Bluetooth para conectar com seu smartwatch</string>
```

---

## Segurança

O PulseFlow Mobile implementa várias camadas de segurança para proteger os dados dos pacientes:

- **Autenticação JWT** - Tokens seguros com expiração automática
- **Armazenamento Criptografado** - Dados sensíveis protegidos com Flutter Secure Storage
- **Pulse Key Temporário** - Sistema de compartilhamento seguro e controlado
- **Validação de Dados** - Validação tanto no cliente quanto no servidor
- **HTTPS** - Comunicação criptografada com o backend
- **Autenticação de Dois Fatores** - Camada adicional de segurança no login

---

## Testes

### Executar Testes

```bash
# Executar todos os testes
flutter test

# Executar testes com cobertura
flutter test --coverage
```

### Estrutura de Testes

Os testes devem ser organizados seguindo a estrutura do projeto, com arquivos de teste correspondentes aos arquivos de código fonte.

---

## Troubleshooting

### Erro de Conexão com API

**Problema:** O aplicativo não consegue conectar com o backend.

**Soluções:**
- Verifique se o backend está em execução na porta configurada
- Confirme a URL no arquivo `.env` (variável `API_BASE_URL`)
- Teste a conectividade de rede
- Verifique se o firewall não está bloqueando a conexão

### Erro de Firebase

**Problema:** Erros relacionados ao Firebase ou notificações push.

**Soluções:**
- Verifique se os arquivos de configuração estão nos locais corretos
- Confirme as credenciais do Firebase Console
- Reinstale o aplicativo após configurar o Firebase
- Verifique se o projeto Firebase está ativo

### Erro de Permissões

**Problema:** O aplicativo não consegue acessar recursos do dispositivo.

**Soluções:**
- **Android:** Verifique `AndroidManifest.xml` para permissões necessárias
- **iOS:** Verifique `Info.plist` para descrições de uso
- Solicite permissões em tempo de execução quando necessário
- Verifique as configurações de privacidade do dispositivo

### Erro de Build

**Problema:** Erros ao compilar o aplicativo.

**Soluções:**
- Execute `flutter clean` e depois `flutter pub get`
- Verifique se todas as dependências estão atualizadas
- Confirme que o Flutter SDK está na versão correta
- Verifique os logs de erro para mais detalhes

---

## Licença

Este projeto é proprietário e confidencial. Todos os direitos reservados.

---

## Suporte

Para questões, suporte ou sugestões:

- **Email:** pulseflowsaude@gmail.com

---

<div align="center">

Desenvolvido com Flutter

</div>
