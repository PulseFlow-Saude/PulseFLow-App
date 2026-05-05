/**
 * Exemplo de endpoint esperado pelo app Flutter (POST JSON).
 *
 * Variáveis de ambiente sugeridas:
 *   EMAIL_API_SECRET — igual ao .env do app (header X-PulseFlow-Email-Secret)
 *   SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS — servidor que aceita login (ex. SendGrid)
 *
 * Copia a rota para o teu backend (Express/Fastify/etc.) e usa nodemailer ou API do provedor.
 *
 * npm install express nodemailer
 * node scripts/send-2fa-email-route.example.js
 */

const express = require('express');
const nodemailer = require('nodemailer');

const app = express();
app.use(express.json());

const PORT = process.env.PORT || 65432;
const SECRET = process.env.EMAIL_API_SECRET || '';

const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST || 'smtp.sendgrid.net',
  port: Number(process.env.SMTP_PORT || 587),
  secure: false,
  auth: {
    user: process.env.SMTP_USER || '',
    pass: process.env.SMTP_PASS || '',
  },
});

app.post('/api/paciente-auth/send-2fa-email', async (req, res) => {
  try {
    if (SECRET && req.headers['x-pulseflow-email-secret'] !== SECRET) {
      return res.status(401).json({ message: 'Secret inválido' });
    }

    const { email, to, code, patientId } = req.body || {};
    const dest = email || to;
    if (!dest || !code) {
      return res.status(400).json({ message: 'Campos email/to e code obrigatórios' });
    }

    await transporter.sendMail({
      from: process.env.MAIL_FROM || '"Oryon Health" <noreply@example.com>',
      to: dest,
      subject: 'Código de verificação - Oryon Health',
      text: `O teu código é: ${code}\n\nExpira em 5 minutos.`,
      html: `<p>O teu código é: <strong>${code}</strong></p><p>Expira em 5 minutos.</p>`,
    });

    console.log(`[2FA] enviado para ${dest} patientId=${patientId || '-'}`);
    return res.status(200).json({ ok: true });
  } catch (e) {
    console.error(e);
    return res.status(500).json({ message: String(e.message || e) });
  }
});

app.listen(PORT, () => {
  console.log(`Exemplo send-2FA escuta em http://0.0.0.0:${PORT}`);
});
