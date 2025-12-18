const fs = require('fs');
const path = require('path');

const envPath = path.join(__dirname, '..', '.env');
const outputPath = path.join(__dirname, '..', 'web', 'firebase-config.js');

if (!fs.existsSync(envPath)) {
  console.error('❌ Arquivo .env não encontrado em:', envPath);
  console.error('   Crie o arquivo .env com as variáveis do Firebase antes de continuar.');
  process.exit(1);
}

let envContent = {};
const envFile = fs.readFileSync(envPath, 'utf8');
envFile.split('\n').forEach(line => {
  const trimmedLine = line.trim();
  if (trimmedLine && !trimmedLine.startsWith('#')) {
    const [key, ...valueParts] = trimmedLine.split('=');
    if (key && valueParts.length > 0) {
      envContent[key.trim()] = valueParts.join('=').trim();
    }
  }
});

const requiredVars = [
  'FIREBASE_WEB_API_KEY',
  'FIREBASE_AUTH_DOMAIN',
  'FIREBASE_PROJECT_ID',
  'FIREBASE_STORAGE_BUCKET',
  'FIREBASE_MESSAGING_SENDER_ID',
  'FIREBASE_WEB_APP_ID'
];

const missingVars = requiredVars.filter(varName => !envContent[varName]);
if (missingVars.length > 0) {
  console.warn('⚠️  Variáveis faltando no .env:');
  missingVars.forEach(varName => console.warn(`   - ${varName}`));
  console.warn('   O arquivo será gerado, mas pode não funcionar corretamente.');
}

const config = `const firebaseConfig = {
  apiKey: "${envContent.FIREBASE_WEB_API_KEY || ''}",
  authDomain: "${envContent.FIREBASE_AUTH_DOMAIN || ''}",
  projectId: "${envContent.FIREBASE_PROJECT_ID || ''}",
  storageBucket: "${envContent.FIREBASE_STORAGE_BUCKET || ''}",
  messagingSenderId: "${envContent.FIREBASE_MESSAGING_SENDER_ID || ''}",
  appId: "${envContent.FIREBASE_WEB_APP_ID || ''}"
};
`;

const outputDir = path.dirname(outputPath);
if (!fs.existsSync(outputDir)) {
  fs.mkdirSync(outputDir, { recursive: true });
}

fs.writeFileSync(outputPath, config, 'utf8');
console.log('✅ firebase-config.js gerado com sucesso!');

