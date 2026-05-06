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

function escapeHtml(value = '') {
  return String(value)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
}

function buildEmailTemplate({ code, isReset }) {
  const safeCode = escapeHtml(code);
  const title = isReset ? 'Redefinicao de senha' : 'Verificacao em duas etapas';
  const subtitle = isReset
    ? 'Use o codigo abaixo para redefinir sua senha.'
    : 'Use o codigo abaixo para concluir seu login com seguranca.';
  const expiry = isReset ? 'Expira em 10 minutos.' : 'Expira em 5 minutos.';
  const supportHint = isReset
    ? 'Se voce nao solicitou redefinicao de senha, ignore este e-mail.'
    : 'Se voce nao iniciou este login, desconsidere este e-mail.';

  return `
<!doctype html>
<html lang="pt-BR">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>${title} - Oryon Health</title>
  </head>
  <body style="margin:0;padding:0;background-color:#f2f6fa;font-family:Arial,Helvetica,sans-serif;color:#1f2a37;">
    <div style="display:none;max-height:0;overflow:hidden;opacity:0;">
      ${title} - seu codigo e ${safeCode}. ${expiry}
    </div>
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="background-color:#f2f6fa;padding:24px 12px;">
      <tr>
        <td align="center">
          <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="max-width:560px;background:#ffffff;border-radius:18px;overflow:hidden;border:1px solid #dbe7f2;">
            <tr>
              <td style="background:linear-gradient(135deg,#00324a 0%,#0b4c6b 100%);padding:24px 24px 20px;text-align:center;">
                <div style="font-size:12px;line-height:1;color:#8ec2e0;letter-spacing:1px;font-weight:700;">ORYON HEALTH</div>
                <div style="font-size:22px;line-height:1.35;color:#ffffff;font-weight:700;margin-top:10px;">${title}</div>
              </td>
            </tr>
            <tr>
              <td style="padding:24px;">
                <p style="margin:0 0 10px;font-size:15px;line-height:1.5;color:#334155;">${subtitle}</p>
                <p style="margin:0 0 18px;font-size:14px;line-height:1.5;color:#64748b;">${expiry}</p>

                <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="margin:0 0 18px;">
                  <tr>
                    <td style="background:#f8fbfe;border:1px solid #cfe0ee;border-radius:14px;padding:16px;text-align:center;">
                      <div style="font-size:12px;line-height:1;color:#4b6478;font-weight:700;letter-spacing:0.7px;">CODIGO DE VERIFICACAO</div>
                      <div style="margin-top:10px;font-size:34px;line-height:1.1;font-weight:800;letter-spacing:8px;color:#00324a;">${safeCode}</div>
                    </td>
                  </tr>
                </table>

                <div style="background:#ecf5fb;border-left:4px solid #64b5f6;border-radius:10px;padding:12px 14px;margin-bottom:14px;">
                  <p style="margin:0;font-size:13px;line-height:1.5;color:#35556d;">
                    Por seguranca, nunca compartilhe este codigo com terceiros.
                  </p>
                </div>

                <p style="margin:0;font-size:13px;line-height:1.5;color:#64748b;">${supportHint}</p>
              </td>
            </tr>
            <tr>
              <td style="padding:16px 24px 22px;border-top:1px solid #e5edf4;">
                <p style="margin:0;font-size:12px;line-height:1.5;color:#8aa0b4;text-align:center;">
                  Este e-mail foi enviado automaticamente pelo PulseFlow App.
                </p>
              </td>
            </tr>
          </table>
        </td>
      </tr>
    </table>
  </body>
</html>
  `.trim();
}

app.post('/api/paciente-auth/send-2fa-email', async (req, res) => {
  try {
    if (SECRET && req.headers['x-pulseflow-email-secret'] !== SECRET) {
      return res.status(401).json({ message: 'Secret inválido' });
    }

    const { email, to, code, patientId, kind } = req.body || {};
    const dest = email || to;
    if (!dest || !code) {
      return res.status(400).json({ message: 'Campos email/to e code obrigatórios' });
    }

    const isReset = kind === 'password_reset';
    const subject = isReset
      ? 'Redefinição de senha - Oryon Health'
      : 'Código de verificação - Oryon Health';
    const text = isReset
      ? `Codigo para redefinir a senha: ${code}\nExpira em 10 minutos.\n\nPor seguranca, nunca compartilhe este codigo.\nSe voce nao solicitou redefinicao de senha, ignore este e-mail.`
      : `Seu codigo de verificacao: ${code}\nExpira em 5 minutos.\n\nPor seguranca, nunca compartilhe este codigo.\nSe voce nao iniciou este login, desconsidere este e-mail.`;
    const html = buildEmailTemplate({ code, isReset });

    await transporter.sendMail({
      from: process.env.MAIL_FROM || '"Oryon Health" <noreply@example.com>',
      to: dest,
      subject,
      text,
      html,
    });

    console.log(`[email kind=${kind || 'login_2fa'}] enviado para ${dest} patientId=${patientId || '-'}`);
    return res.status(200).json({ ok: true });
  } catch (e) {
    console.error(e);
    return res.status(500).json({ message: String(e.message || e) });
  }
});

app.listen(PORT, () => {
  console.log(`Exemplo send-2FA escuta em http://0.0.0.0:${PORT}`);
});
