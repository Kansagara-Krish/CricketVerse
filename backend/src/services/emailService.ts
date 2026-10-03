import nodemailer from 'nodemailer';
import { EmailConfigModel, IEmailConfig } from '../models/EmailConfig';

export interface EmailConfigPublic {
  isConfigured: boolean;
  senderEmail: string;
  senderName: string;
  host: string;
  port: number;
  secure: boolean;
  hasAppPassword: boolean;
  updatedAt?: string;
  updatedBy?: string;
}

export interface UpdateEmailConfigInput {
  senderEmail: string;
  appPassword?: string;
  senderName?: string;
  host?: string;
  port?: number;
  secure?: boolean;
  updatedBy?: string;
}

/**
 * Retrieves the active email configuration from MongoDB or environment variables fallback.
 */
export async function getActiveEmailConfig(): Promise<{
  senderEmail: string;
  senderName: string;
  appPassword: string;
  host: string;
  port: number;
  secure: boolean;
  isConfigured: boolean;
} | null> {
  try {
    const dbConfig = await EmailConfigModel.findOne({ id: 'global_email_config' });
    if (dbConfig && dbConfig.isConfigured && dbConfig.senderEmail && dbConfig.appPassword) {
      return {
        senderEmail: dbConfig.senderEmail,
        senderName: dbConfig.senderName || 'CricketVerse',
        appPassword: dbConfig.appPassword,
        host: dbConfig.host || 'smtp.gmail.com',
        port: dbConfig.port || 465,
        secure: dbConfig.secure !== undefined ? dbConfig.secure : true,
        isConfigured: true,
      };
    }

    // Fallback to environment variables if present
    const envEmail = process.env.SMTP_EMAIL || process.env.EMAIL_USER;
    const envPass = process.env.SMTP_APP_PASSWORD || process.env.EMAIL_PASS;
    if (envEmail && envPass) {
      return {
        senderEmail: envEmail,
        senderName: process.env.SMTP_SENDER_NAME || 'CricketVerse',
        appPassword: envPass,
        host: process.env.SMTP_HOST || 'smtp.gmail.com',
        port: Number(process.env.SMTP_PORT) || 465,
        secure: process.env.SMTP_SECURE === 'false' ? false : true,
        isConfigured: true,
      };
    }

    return null;
  } catch (err) {
    console.error('Error getting active email config:', err);
    return null;
  }
}

/**
 * Returns the public email config for Admin inspection (WITHOUT the app password).
 */
export async function getPublicEmailConfig(): Promise<EmailConfigPublic> {
  const dbConfig = await EmailConfigModel.findOne({ id: 'global_email_config' });
  const envEmail = process.env.SMTP_EMAIL || process.env.EMAIL_USER;
  const envPass = process.env.SMTP_APP_PASSWORD || process.env.EMAIL_PASS;

  if (dbConfig && dbConfig.senderEmail) {
    return {
      isConfigured: dbConfig.isConfigured,
      senderEmail: dbConfig.senderEmail,
      senderName: dbConfig.senderName || 'CricketVerse',
      host: dbConfig.host || 'smtp.gmail.com',
      port: dbConfig.port || 465,
      secure: dbConfig.secure !== undefined ? dbConfig.secure : true,
      hasAppPassword: Boolean(dbConfig.appPassword && dbConfig.appPassword.length > 0),
      updatedAt: dbConfig.updatedAt ? dbConfig.updatedAt.toISOString() : undefined,
      updatedBy: dbConfig.updatedBy || 'Admin',
    };
  }

  if (envEmail) {
    return {
      isConfigured: Boolean(envPass),
      senderEmail: envEmail,
      senderName: process.env.SMTP_SENDER_NAME || 'CricketVerse',
      host: process.env.SMTP_HOST || 'smtp.gmail.com',
      port: Number(process.env.SMTP_PORT) || 465,
      secure: process.env.SMTP_SECURE === 'false' ? false : true,
      hasAppPassword: Boolean(envPass),
      updatedAt: new Date().toISOString(),
      updatedBy: 'Environment (.env)',
    };
  }

  return {
    isConfigured: false,
    senderEmail: '',
    senderName: 'CricketVerse',
    host: 'smtp.gmail.com',
    port: 465,
    secure: true,
    hasAppPassword: false,
  };
}

/**
 * Creates and verifies a Nodemailer transporter.
 */
export function createTransporter(config: {
  senderEmail: string;
  appPassword: string;
  host?: string;
  port?: number;
  secure?: boolean;
}) {
  const host = config.host || 'smtp.gmail.com';
  const port = config.port || 465;
  const secure = config.secure !== undefined ? config.secure : port === 465;

  return nodemailer.createTransport({
    host,
    port,
    secure,
    auth: {
      user: config.senderEmail,
      pass: config.appPassword,
    },
    tls: {
      rejectUnauthorized: false, // Prevents self-signed / ISP TLS issues in dev
    },
    connectionTimeout: 10000,
    greetingTimeout: 10000,
    socketTimeout: 15000,
  });
}

/**
 * Updates or sets the email configuration in DB.
 * App password is saved only if a fresh one is provided.
 */
export async function saveEmailConfig(input: UpdateEmailConfigInput): Promise<EmailConfigPublic> {
  const existing = await EmailConfigModel.findOne({ id: 'global_email_config' });

  const senderEmail = input.senderEmail.trim();
  const senderName = input.senderName?.trim() || 'CricketVerse';
  const host = input.host?.trim() || 'smtp.gmail.com';
  const port = input.port || (host.includes('gmail') ? 465 : 587);
  const secure = input.secure !== undefined ? input.secure : port === 465;

  let appPassword = existing?.appPassword || '';
  if (input.appPassword && input.appPassword.trim().length > 0) {
    // Fresh app password provided by admin (clean spaces often generated in Google App Passwords like "abcd efgh ijkl mnop")
    appPassword = input.appPassword.replace(/\s+/g, '');
  }

  if (!appPassword) {
    throw new Error('An App Password is required to configure email sending.');
  }

  // Verify SMTP connection before saving
  const testTransporter = createTransporter({
    senderEmail,
    appPassword,
    host,
    port,
    secure,
  });

  try {
    await testTransporter.verify();
  } catch (verifyErr: any) {
    console.error('SMTP credentials verification failed:', verifyErr);
    throw new Error(
      `SMTP connection test failed: ${verifyErr.message || 'Please verify your email address and App Password.'}`
    );
  }

  const updated = await EmailConfigModel.findOneAndUpdate(
    { id: 'global_email_config' },
    {
      $set: {
        senderEmail,
        senderName,
        appPassword,
        host,
        port,
        secure,
        isConfigured: true,
        updatedBy: input.updatedBy || 'Admin',
      },
    },
    { upsert: true, new: true }
  );

  return {
    isConfigured: true,
    senderEmail: updated.senderEmail,
    senderName: updated.senderName,
    host: updated.host,
    port: updated.port,
    secure: updated.secure,
    hasAppPassword: true,
    updatedAt: updated.updatedAt?.toISOString(),
    updatedBy: updated.updatedBy,
  };
}

/**
 * Sends a stylized HTML OTP Email for Password Reset.
 */
export async function sendPasswordResetOtpEmail(
  toEmail: string,
  otpCode: string,
  recipientName?: string
): Promise<{ success: boolean; messageId?: string; error?: string }> {
  const config = await getActiveEmailConfig();

  if (!config || !config.isConfigured) {
    console.warn(
      `⚠️ [EMAIL NOT CONFIGURED] OTP for ${toEmail} is [${otpCode}]. (Admin has not configured sender email & app password yet).`
    );
    return {
      success: false,
      error:
        'Email service is not yet configured by the administrator. Please contact the administrator or configure SMTP settings in Admin Panel.',
    };
  }

  const transporter = createTransporter(config);
  const displayName = recipientName && recipientName.trim().length > 0 ? recipientName.trim() : 'CricketVerse Member';

  const htmlContent = `
  <!DOCTYPE html>
  <html>
  <head>
    <meta charset="utf-8">
    <title>CricketVerse OTP Verification</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
  </head>
  <body style="margin: 0; padding: 0; background-color: #0b111e; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; color: #ffffff;">
    <table border="0" cellpadding="0" cellspacing="0" width="100%" style="table-layout: fixed; background-color: #0b111e; padding: 40px 10px;">
      <tr>
        <td align="center">
          <table border="0" cellpadding="0" cellspacing="0" width="100%" style="max-width: 520px; background: linear-gradient(145deg, #131d2e 0%, #0d1522 100%); border: 1px solid rgba(255, 255, 255, 0.12); border-radius: 20px; box-shadow: 0 20px 40px rgba(0,0,0,0.6); overflow: hidden;">
            <!-- Header Banner -->
            <tr>
              <td style="padding: 32px 32px 20px 32px; text-align: center; border-bottom: 1px solid rgba(255,255,255,0.08);">
                <div style="display: inline-block; padding: 10px 18px; border-radius: 12px; background: linear-gradient(135deg, #028A6B, #00B0FF); margin-bottom: 12px;">
                  <span style="font-size: 22px; font-weight: 900; color: #ffffff; letter-spacing: 1px;">CRICKETVERSE AI</span>
                </div>
                <h2 style="margin: 8px 0 0 0; color: #ffffff; font-size: 20px; font-weight: 700;">Password Reset Request</h2>
              </td>
            </tr>

            <!-- Body -->
            <tr>
              <td style="padding: 32px; color: #cbd5e1; font-size: 15px; line-height: 1.6;">
                <p style="margin: 0 0 16px 0; color: #f8fafc; font-size: 16px; font-weight: 600;">
                  Hello ${displayName},
                </p>
                <p style="margin: 0 0 24px 0; color: #94a3b8;">
                  We received a request to reset your password for your CricketVerse account. Use the one-time verification code (OTP) below to complete your password update.
                </p>

                <!-- OTP Code Display Card -->
                <div style="background: rgba(2, 138, 107, 0.12); border: 1.5px dashed #00B0FF; border-radius: 14px; padding: 22px; text-align: center; margin: 24px 0;">
                  <div style="font-size: 12px; font-weight: 700; text-transform: uppercase; letter-spacing: 2px; color: #00B0FF; margin-bottom: 6px;">
                    Your One-Time Password
                  </div>
                  <div style="font-size: 36px; font-weight: 900; letter-spacing: 8px; color: #ffffff; font-family: monospace; text-shadow: 0 0 16px rgba(0, 176, 255, 0.6);">
                    ${otpCode}
                  </div>
                  <div style="font-size: 12px; color: #94a3b8; margin-top: 8px;">
                    ⏱️ Code expires in <strong>10 minutes</strong>.
                  </div>
                </div>

                <p style="margin: 24px 0 0 0; font-size: 13px; color: #64748b; line-height: 1.5;">
                  🔒 <strong>Security Tip:</strong> Never share this OTP with anyone. If you did not request a password reset, you can safely ignore this email — your account remains secure.
                </p>
              </td>
            </tr>

            <!-- Footer -->
            <tr>
              <td style="background-color: rgba(0,0,0,0.3); padding: 20px 32px; text-align: center; font-size: 12px; color: #64748b; border-top: 1px solid rgba(255,255,255,0.06);">
                © ${new Date().getFullYear()} CricketVerse AI Platform. All rights reserved.
              </td>
            </tr>
          </table>
        </td>
      </tr>
    </table>
  </body>
  </html>
  `;

  try {
    const info = await transporter.sendMail({
      from: `"${config.senderName}" <${config.senderEmail}>`,
      to: toEmail,
      subject: `🏏 CricketVerse OTP: ${otpCode} - Reset Your Password`,
      text: `Hello ${displayName},\n\nYour CricketVerse password reset OTP is: ${otpCode}\n\nThis OTP is valid for 10 minutes. If you did not request this, please ignore this email.\n\nCricketVerse Team`,
      html: htmlContent,
    });

    console.log(`✅ Password reset OTP email successfully sent to ${toEmail}. MessageId: ${info.messageId}`);
    return { success: true, messageId: info.messageId };
  } catch (sendErr: any) {
    console.error(`❌ Failed to send password reset email to ${toEmail}:`, sendErr);
    return { success: false, error: sendErr.message || 'Failed to send email.' };
  }
}

/**
 * Test sending an email to verify SMTP configuration
 */
export async function sendTestEmail(targetEmail: string): Promise<{ success: boolean; error?: string }> {
  const config = await getActiveEmailConfig();
  if (!config || !config.isConfigured) {
    return { success: false, error: 'Email service is not configured.' };
  }

  const transporter = createTransporter(config);
  try {
    await transporter.sendMail({
      from: `"${config.senderName}" <${config.senderEmail}>`,
      to: targetEmail,
      subject: '🏏 CricketVerse - SMTP Configuration Test Successful',
      html: `
        <div style="font-family: sans-serif; padding: 20px; background-color: #0b111e; color: #fff; border-radius: 12px;">
          <h2 style="color: #00B0FF;">CricketVerse SMTP Test</h2>
          <p>Congratulations! Your sender email configuration (<strong>${config.senderEmail}</strong>) is active and working properly.</p>
          <p style="color: #94a3b8; font-size: 12px;">Sent at: ${new Date().toLocaleString()}</p>
        </div>
      `,
    });
    return { success: true };
  } catch (err: any) {
    return { success: false, error: err.message || 'Failed to send test email.' };
  }
}
