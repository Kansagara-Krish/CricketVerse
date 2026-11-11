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

    // Fallback to Render/Cloud Environment Variables if DB config is missing
    const envUser = process.env.SMTP_USER?.trim();
    const envPass = process.env.SMTP_PASS?.trim();
    if (envUser && envPass) {
      const envHost = process.env.SMTP_HOST?.trim() || 'smtp.gmail.com';
      const envPort = Number(process.env.SMTP_PORT || 465);
      return {
        senderEmail: process.env.SMTP_FROM?.trim() || envUser,
        senderName: 'CricketVerse AI',
        appPassword: envPass,
        host: envHost,
        port: envPort,
        secure: envPort === 465,
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

  return nodemailer.createTransport({
    host: isGmail ? 'smtp.gmail.com' : host,
    port,
    secure,
    auth: {
      user: config.senderEmail.trim(),
      pass: config.appPassword.replace(/\s+/g, ''),
    },
    tls: {
      rejectUnauthorized: false,
    },
    family: 4, // Force IPv4 to prevent ENETUNREACH on cloud hosts without IPv6 egress
    connectionTimeout: 5000,
    greetingTimeout: 5000,
    socketTimeout: 7000,
  } as any);
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
