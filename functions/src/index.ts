import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import nodemailer from 'nodemailer';

// Initialize Firebase Admin SDK
admin.initializeApp();

// Configure email transporter (using Gmail SMTP)
// IMPORTANTE: Configurar variáveis de ambiente
// firebase functions:config:set gmail.user="seu_email@gmail.com" gmail.password="sua_senha_app"
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: functions.config().gmail?.user || process.env.GMAIL_USER,
    pass: functions.config().gmail?.password || process.env.GMAIL_PASSWORD,
  },
});

/**
 * Send OTP via Email
 * Called from Flutter app via FirebaseFunctions.instance.httpsCallable('sendOtpEmail')
 */
export const sendOtpEmail = functions.https.onCall(async (data, context) => {
  // Verificar autenticação
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Utilizador nao autenticado'
    );
  }

  const { email, otp, phone, userName } = data;

  // Validar entrada
  if (!email || !otp || !phone) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Email, OTP e telefone sao obrigatorios'
    );
  }

  // Validar formato de email
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(email)) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Email invalido'
    );
  }

  // Validar OTP (6 digitos)
  if (!/^\d{6}$/.test(otp)) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'OTP deve ser 6 digitos'
    );
  }

  try {
    const mailOptions = {
      from: `BJBank <${functions.config().gmail?.user || process.env.GMAIL_USER}>`,
      to: email,
      subject: 'Codigo de Verificacao MB WAY - BJBank',
      html: generateEmailTemplate(otp, phone, userName || 'Utilizador'),
      text: `Seu codigo OTP para ativar MB WAY: ${otp}\n\nValidade: 5 minutos\n\nTelefone: ${phone}\n\nNao compartilhe este codigo com ninguem.`,
    };

    // Enviar email
    await transporter.sendMail(mailOptions);

    // Log no Firestore para auditoria
    await admin
      .firestore()
      .collection('audit_logs')
      .add({
        action: 'otp_email_sent',
        userId: context.auth.uid,
        email: email,
        phone: phone,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

    return {
      success: true,
      message: `Codigo enviado para ${maskEmail(email)}`,
    };
  } catch (error) {
    console.error('Erro ao enviar email:', error);

    // Log de erro
    await admin
      .firestore()
      .collection('error_logs')
      .add({
        action: 'otp_email_failed',
        userId: context.auth.uid,
        email: email,
        error: error instanceof Error ? error.message : String(error),
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

    throw new functions.https.HttpsError(
      'internal',
      'Erro ao enviar codigo. Tente novamente.'
    );
  }
});

/**
 * Email template HTML
 */
function generateEmailTemplate(otp: string, phone: string, userName: string): string {
  return `
    <!DOCTYPE html>
    <html lang="pt-PT">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <style>
        body {
          font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
          line-height: 1.6;
          color: #333;
          background-color: #f5f5f5;
        }
        .container {
          max-width: 600px;
          margin: 20px auto;
          background: white;
          border-radius: 8px;
          overflow: hidden;
          box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .header {
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          color: white;
          padding: 30px;
          text-align: center;
        }
        .header h1 {
          margin: 0;
          font-size: 24px;
          font-weight: 600;
        }
        .content {
          padding: 30px;
        }
        .greeting {
          margin-bottom: 20px;
          font-size: 14px;
          color: #666;
        }
        .otp-section {
          background: #f9f9f9;
          border-left: 4px solid #667eea;
          padding: 20px;
          margin: 20px 0;
          border-radius: 4px;
        }
        .otp-label {
          font-size: 12px;
          color: #999;
          text-transform: uppercase;
          letter-spacing: 1px;
          margin-bottom: 10px;
        }
        .otp-code {
          font-size: 36px;
          font-weight: bold;
          color: #667eea;
          letter-spacing: 6px;
          text-align: center;
          font-family: 'Courier New', monospace;
          margin: 20px 0;
        }
        .info-section {
          background: #f0f4ff;
          padding: 15px;
          border-radius: 4px;
          margin: 20px 0;
          font-size: 13px;
          color: #555;
        }
        .info-item {
          margin: 8px 0;
          display: flex;
          align-items: center;
        }
        .info-item strong {
          min-width: 80px;
        }
        .warning {
          background: #fff3cd;
          border-left: 4px solid #ffc107;
          padding: 15px;
          margin: 20px 0;
          border-radius: 4px;
          font-size: 13px;
          color: #856404;
        }
        .footer {
          background: #f5f5f5;
          padding: 20px;
          text-align: center;
          font-size: 12px;
          color: #999;
          border-top: 1px solid #eee;
        }
        .footer-text {
          margin: 5px 0;
        }
        .button {
          display: inline-block;
          background: #667eea;
          color: white;
          padding: 12px 30px;
          text-decoration: none;
          border-radius: 4px;
          margin: 20px 0;
        }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>🔐 Verificacao MB WAY</h1>
          <p>Codigo de Confirmacao Seguro</p>
        </div>

        <div class="content">
          <div class="greeting">
            Ola ${userName},
          </div>

          <p>
            Recebemos um pedido para ativar o MB WAY na sua conta BJBank.
          </p>

          <div class="otp-section">
            <div class="otp-label">Seu Codigo de Verificacao</div>
            <div class="otp-code">${otp}</div>
            <div style="text-align: center; color: #999; font-size: 12px;">
              Validade: 5 minutos
            </div>
          </div>

          <div class="info-section">
            <div class="info-item">
              <strong>Telefone:</strong> ${phone}
            </div>
            <div class="info-item">
              <strong>Servico:</strong> Ativacao MB WAY
            </div>
            <div class="info-item">
              <strong>Horario:</strong> ${new Date().toLocaleString('pt-PT')}
            </div>
          </div>

          <div class="warning">
            <strong>⚠️ Seguranca</strong><br>
            Nunca compartilhe este codigo com ninguem. BJBank nunca solicitara este codigo por telefone ou email.
            Se nao solicitou este codigo, ignore esta mensagem.
          </div>

          <p style="font-size: 13px; color: #666; margin-top: 30px;">
            Se tiver duvidas ou nao reconhece esta atividade, contacte o nosso suporte.
          </p>
        </div>

        <div class="footer">
          <div class="footer-text">BJBank - Sistema de Pagamentos Seguro</div>
          <div class="footer-text">Email automatico - Nao responda a este email</div>
          <div class="footer-text">© 2024 BJBank. Todos os direitos reservados.</div>
        </div>
      </div>
    </body>
    </html>
  `;
}

/**
 * Mask email para privacidade
 * exemplo@domain.com -> exa***@domain.com
 */
function maskEmail(email: string): string {
  const [local, domain] = email.split('@');
  const masked = local.substring(0, 3) + '***';
  return `${masked}@${domain}`;
}
