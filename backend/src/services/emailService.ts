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
 * Retrieves the active email configuration exclusively from MongoDB database.
 * Dynamic database storage allows administrators to update credentials without server restart.
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
    return null;
  } catch (err) {
    console.error('Error fetching email configuration from database:', err);
    return null;
  }
}

/**
 * Returns the public email config from MongoDB for Admin inspection (WITHOUT exposing app password).
 */
export async function getPublicEmailConfig(): Promise<EmailConfigPublic> {
  try {
    const dbConfig = await EmailConfigModel.findOne({ id: 'global_email_config' });

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
  } catch (err) {
    console.error('Error fetching public email config from database:', err);
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
  const host = (config.host || 'smtp.gmail.com').trim();
  const isGmail = host.toLowerCase().includes('gmail');
  const port = config.port || (isGmail ? 465 : 587);
  const secure = config.secure !== undefined ? config.secure : port === 465;

  if (isGmail) {
    return nodemailer.createTransport({
      service: 'gmail',
      auth: {
        user: config.senderEmail.trim(),
        pass: config.appPassword.replace(/\s+/g, ''),
      },
      tls: {
        rejectUnauthorized: false,
      },
      connectionTimeout: 15000,
      greetingTimeout: 15000,
      socketTimeout: 20000,
    });
  }

  return nodemailer.createTransport({
    host,
    port,
    secure,
    auth: {
      user: config.senderEmail.trim(),
      pass: config.appPassword.replace(/\s+/g, ''),
    },
    tls: {
      rejectUnauthorized: false,
    },
    connectionTimeout: 15000,
    greetingTimeout: 15000,
    socketTimeout: 20000,
  });
}

/**
 * Updates or sets the email configuration in MongoDB.
 * App password is saved only if a fresh one is provided.
 */
export async function saveEmailConfig(input: UpdateEmailConfigInput): Promise<EmailConfigPublic> {
  const existing = await EmailConfigModel.findOne({ id: 'global_email_config' });

  const senderEmail = input.senderEmail.trim().toLowerCase();
  const senderName = input.senderName?.trim() || 'CricketVerse';
  const host = input.host?.trim() || 'smtp.gmail.com';
  const port = input.port || (host.includes('gmail') ? 465 : 587);
  const secure = input.secure !== undefined ? input.secure : port === 465;

  let appPassword = existing?.appPassword || '';
  const isFreshPassword = Boolean(input.appPassword && input.appPassword.trim().length > 0);
  if (isFreshPassword) {
    appPassword = input.appPassword!.replace(/\s+/g, '');
  }

  if (!appPassword) {
    throw new Error('An App Password is required to configure email sending.');
  }

  // Only perform network SMTP verify if a new password is provided or email changed or not yet verified
  const isAlreadyVerified = Boolean(
    existing &&
    existing.isConfigured &&
    existing.appPassword &&
    existing.senderEmail.toLowerCase() === senderEmail
  );
  const needsVerification = isFreshPassword || !isAlreadyVerified;

  if (needsVerification) {
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
    { upsert: true, returnDocument: 'after' }
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
 * Sends a stylized, executive HTML OTP Email for Password Reset.
 */
export async function sendPasswordResetOtpEmail(
  toEmail: string,
  otpCode: string,
  recipientName?: string
): Promise<{ success: boolean; messageId?: string; error?: string }> {
  const config = await getActiveEmailConfig();

  if (!config || !config.isConfigured) {
    console.warn(
      `⚠️ [EMAIL NOT CONFIGURED] OTP for ${toEmail} is [${otpCode}]. (No active SMTP config found in database).`
    );
    return {
      success: false,
      error:
        'Email service is not configured in the database. Please configure SMTP settings in Admin Panel.',
    };
  }

  const transporter = createTransporter(config);
  const displayName = recipientName && recipientName.trim().length > 0 ? recipientName.trim() : 'CricketVerse Member';

  const htmlContent = `
  <!DOCTYPE html>
  <html lang="en">
  <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>CricketVerse Verification Code</title>
  </head>
  <body style="margin: 0; padding: 0; background-color: #f1f5f9; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; color: #1e293b;">
    <table width="100%" border="0" cellspacing="0" cellpadding="0" style="background-color: #f1f5f9; padding: 36px 12px;">
      <tr>
        <td align="center">
          <table width="100%" border="0" cellspacing="0" cellpadding="0" style="max-width: 480px; background-color: #ffffff; border-radius: 16px; border: 1px solid #e2e8f0; box-shadow: 0 4px 20px rgba(0, 0, 0, 0.05); overflow: hidden;">
            
            <!-- Brand Header -->
            <tr>
              <td style="padding: 28px 24px 20px 24px; text-align: center; border-bottom: 1px solid #f1f5f9;">
                <div style="display: inline-block; padding: 6px 16px; border-radius: 10px; background: linear-gradient(135deg, #0284c7, #059669);">
                  <span style="font-size: 17px; font-weight: 800; color: #ffffff; letter-spacing: 1.2px;">⚡ CRICKETVERSE</span>
                </div>
                <h2 style="margin: 14px 0 0 0; font-size: 20px; font-weight: 700; color: #0f172a;">Password Reset Code</h2>
              </td>
            </tr>

            <!-- Focused Content -->
            <tr>
              <td style="padding: 28px 24px; text-align: center;">
                <p style="margin: 0 0 6px 0; font-size: 15px; font-weight: 600; color: #334155;">
                  Hello ${displayName},
                </p>
                <p style="margin: 0 0 18px 0; font-size: 14px; color: #64748b; line-height: 1.5;">
                  Here is your verification code to reset your CricketVerse password:
                </p>

                <!-- Focused OTP Box -->
                <div style="background-color: #f8fafc; border: 2px dashed #0284c7; border-radius: 14px; padding: 18px 12px; margin: 16px 0; text-align: center;">
                  <div style="font-size: 40px; font-weight: 900; letter-spacing: 8px; color: #0f172a; font-family: monospace; line-height: 1.2;">
                    ${otpCode}
                  </div>
                  <div style="font-size: 12.5px; font-weight: 600; color: #0284c7; margin-top: 8px;">
                    ⏱️ Code expires in 10 minutes
                  </div>
                </div>

                <p style="margin: 18px 0 0 0; font-size: 12.5px; color: #94a3b8; line-height: 1.5;">
                  If you didn't request a password reset, you can safely ignore this email.
                </p>
              </td>
            </tr>

            <!-- Footer -->
            <tr>
              <td style="padding: 16px 24px; background-color: #f8fafc; border-top: 1px solid #f1f5f9; text-align: center; font-size: 11.5px; color: #94a3b8;">
                © ${new Date().getFullYear()} CricketVerse AI Platform
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
      subject: `🏏 CricketVerse OTP: ${otpCode} - Reset Password`,
      text: `Hello ${displayName},\n\nYour CricketVerse password reset OTP is: ${otpCode}\n\nValid for 10 minutes. If you did not request this, please ignore this email.\n\nCricketVerse Team`,
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
 * Test sending an email to verify SMTP configuration from MongoDB.
 */
export async function sendTestEmail(targetEmail: string): Promise<{ success: boolean; error?: string }> {
  const config = await getActiveEmailConfig();
  if (!config || !config.isConfigured) {
    return { success: false, error: 'Email service is not configured in database.' };
  }

  const transporter = createTransporter(config);
  const htmlContent = `
  <!DOCTYPE html>
  <html lang="en">
  <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>CricketVerse SMTP Verification</title>
  </head>
  <body style="margin: 0; padding: 0; background-color: #f1f5f9; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; color: #1e293b;">
    <table width="100%" border="0" cellspacing="0" cellpadding="0" style="background-color: #f1f5f9; padding: 36px 12px;">
      <tr>
        <td align="center">
          <table width="100%" border="0" cellspacing="0" cellpadding="0" style="max-width: 480px; background-color: #ffffff; border-radius: 16px; border: 1px solid #e2e8f0; box-shadow: 0 4px 20px rgba(0, 0, 0, 0.05); overflow: hidden;">
            
            <!-- Header -->
            <tr>
              <td style="padding: 28px 24px 20px 24px; text-align: center; border-bottom: 1px solid #f1f5f9;">
                <div style="display: inline-block; padding: 6px 16px; border-radius: 10px; background: linear-gradient(135deg, #0284c7, #059669);">
                  <span style="font-size: 17px; font-weight: 800; color: #ffffff; letter-spacing: 1.2px;">⚡ CRICKETVERSE</span>
                </div>
                <h2 style="margin: 14px 0 0 0; font-size: 20px; font-weight: 700; color: #0f172a;">Email Service Verified</h2>
              </td>
            </tr>

            <!-- Content -->
            <tr>
              <td style="padding: 24px; text-align: center;">
                <div style="display: inline-block; padding: 6px 14px; border-radius: 20px; background-color: #ecfdf5; color: #059669; font-size: 13px; font-weight: 700; margin-bottom: 14px;">
                  ✅ SMTP Connected Successfully
                </div>
                <p style="margin: 0 0 16px 0; font-size: 14px; color: #475569; line-height: 1.5;">
                  Your sender configuration is active and working properly from MongoDB storage.
                </p>

                <div style="background-color: #f8fafc; border: 1px solid #e2e8f0; border-radius: 12px; padding: 14px; text-align: left; font-size: 13px; color: #334155;">
                  <div style="margin-bottom: 6px;"><strong>Sender:</strong> ${config.senderEmail}</div>
                  <div><strong>Storage:</strong> MongoDB (Dynamic Config)</div>
                </div>
              </td>
            </tr>

            <!-- Footer -->
            <tr>
              <td style="padding: 16px 24px; background-color: #f8fafc; border-top: 1px solid #f1f5f9; text-align: center; font-size: 11.5px; color: #94a3b8;">
                © ${new Date().getFullYear()} CricketVerse AI Platform
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
    await transporter.sendMail({
      from: `"${config.senderName}" <${config.senderEmail}>`,
      to: targetEmail,
      subject: '🏏 CricketVerse - SMTP Service Verification Successful',
      html: htmlContent,
      text: `CricketVerse SMTP Verification Successful.\nSender: ${config.senderEmail}\nStorage: MongoDB\nTime: ${new Date().toUTCString()}`,
    });
    return { success: true };
  } catch (err: any) {
    return { success: false, error: err.message || 'Failed to send test email.' };
  }
}
