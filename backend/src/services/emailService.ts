import nodemailer from 'nodemailer';
import { Resend } from 'resend';
import { EmailConfigModel, IEmailConfig } from '../models/EmailConfig';

let resendClient: Resend | null = null;
function getResendClient(): Resend | null {
  const apiKey = process.env.RESEND_API_KEY?.trim();
  if (!apiKey) return null;
  if (!resendClient) {
    resendClient = new Resend(apiKey);
  }
  return resendClient;
}

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
 * Sends a branded, secure HTML OTP Email for Password Reset using Resend.
 */
export async function sendPasswordResetOtpViaResend(
  toEmail: string,
  otpCode: string,
  recipientName?: string
): Promise<{ success: boolean; messageId?: string; error?: string }> {
  const resend = getResendClient();
  if (!resend) {
    return {
      success: false,
      error: 'RESEND_API_KEY is not configured on the server.',
    };
  }

  const sender =
    process.env.RESEND_FROM_EMAIL?.trim() || 'CricketVerse AI <onboarding@resend.dev>';
  const displayName =
    recipientName && recipientName.trim().length > 0 ? recipientName.trim() : 'CricketVerse Member';

  const htmlContent = `
  <!DOCTYPE html>
  <html lang="en">
  <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Your CricketVerse AI Password Reset Verification Code</title>
  </head>
  <body style="margin: 0; padding: 0; background-color: #0B1118; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; color: #E2E8F0;">
    <table role="presentation" width="100%" border="0" cellspacing="0" cellpadding="0" style="background-color: #0B1118; padding: 40px 16px;">
      <tr>
        <td align="center">
          <table role="presentation" width="100%" border="0" cellspacing="0" cellpadding="0" style="max-width: 520px; background-color: #101927; border-radius: 16px; border: 1px solid rgba(255,255,255,0.12); box-shadow: 0 10px 40px rgba(0, 0, 0, 0.5); overflow: hidden;">
            
            <!-- Brand Header -->
            <tr>
              <td style="padding: 32px 32px 20px; text-align: center; border-bottom: 1px solid rgba(255,255,255,0.08); background: linear-gradient(180deg, #162235 0%, #101927 100%);">
                <div style="display: inline-block; padding: 8px 18px; border-radius: 999px; background: linear-gradient(135deg, #00E5FF 0%, #00E676 100%); margin-bottom: 14px;">
                  <span style="font-size: 15px; font-weight: 800; color: #0B1118; letter-spacing: 1.5px;">⚡ CRICKETVERSE AI</span>
                </div>
                <h1 style="margin: 10px 0 0; font-size: 22px; font-weight: 700; color: #FFFFFF;">Password Reset Code</h1>
              </td>
            </tr>

            <!-- Content -->
            <tr>
              <td style="padding: 32px 32px 28px;">
                <p style="margin: 0 0 12px; font-size: 15px; font-weight: 600; color: #FFFFFF;">
                  Hello ${displayName},
                </p>
                <p style="margin: 0 0 24px; font-size: 14px; line-height: 1.6; color: #94A3B8;">
                  We received a request to reset your password for your <strong>CricketVerse AI</strong> account. Use the 6-digit verification code below to verify your identity:
                </p>

                <!-- Focused OTP Box -->
                <div style="background-color: #0B1118; border: 1.5px solid #00E5FF; border-radius: 14px; padding: 22px; margin: 24px 0; text-align: center;">
                  <div style="font-size: 38px; font-weight: 800; letter-spacing: 10px; color: #00E676; font-family: 'Courier New', Courier, monospace; margin-left: 10px; line-height: 1.2;">
                    ${otpCode}
                  </div>
                  <div style="font-size: 13px; font-weight: 600; color: #00E5FF; margin-top: 10px;">
                    ⏱️ Code expires in 5 minutes
                  </div>
                </div>

                <!-- Security Alert -->
                <div style="background-color: rgba(239, 68, 68, 0.1); border-left: 4px solid #EF4444; border-radius: 6px; padding: 12px 16px; margin: 24px 0;">
                  <p style="margin: 0; font-size: 13px; color: #FCA5A5; line-height: 1.5;">
                    <strong>Security Alert:</strong> For your security, never share this OTP with anyone. CricketVerse AI representatives will never ask for your verification code.
                  </p>
                </div>

                <p style="margin: 20px 0 0; font-size: 13px; color: #64748B; line-height: 1.5;">
                  If you did not request a password reset, you can safely ignore this email. Your account remains secure.
                </p>
              </td>
            </tr>

            <!-- Footer -->
            <tr>
              <td style="padding: 20px 32px; background-color: #0B1118; border-top: 1px solid rgba(255,255,255,0.06); text-align: center; font-size: 12px; color: #64748B;">
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

  const textContent = `Hello ${displayName},\n\nYour CricketVerse AI password reset verification code is: ${otpCode}\n\nThis code expires in 5 minutes.\n\nSecurity Notice: Never share this OTP with anyone. CricketVerse AI will never ask for your code.\nIf you did not request a password reset, please ignore this email.\n\n© ${new Date().getFullYear()} CricketVerse AI Platform`;

  try {
    const { data, error } = await resend.emails.send({
      from: sender,
      to: [toEmail],
      subject: 'Your CricketVerse AI Password Reset Verification Code',
      html: htmlContent,
      text: textContent,
    });

    if (error) {
      console.error(`❌ Resend API error sending password reset OTP to ${toEmail}:`, error);
      return {
        success: false,
        error: error.message || 'Resend failed to deliver verification email.',
      };
    }

    console.log(`✅ Resend password reset OTP email sent to ${toEmail}. ID: ${data?.id}`);
    return { success: true, messageId: data?.id };
  } catch (err: any) {
    console.error(`❌ Exception sending OTP via Resend to ${toEmail}:`, err);
    return { success: false, error: err.message || 'Internal error delivering email via Resend.' };
  }
}

/**
 * Sends a stylized, executive HTML OTP Email for Password Reset.
 * Uses Resend when RESEND_API_KEY is available, and falls back to configured SMTP if Resend
 * hits testing-tier recipient restrictions or errors.
 */
export async function sendPasswordResetOtpEmail(
  toEmail: string,
  otpCode: string,
  recipientName?: string
): Promise<{ success: boolean; messageId?: string; error?: string }> {
  let resendError: string | undefined;

  // 1. Prioritize Resend if configured
  if (process.env.RESEND_API_KEY && process.env.RESEND_API_KEY.trim().length > 0) {
    const resendResult = await sendPasswordResetOtpViaResend(toEmail, otpCode, recipientName);
    if (resendResult.success) {
      return resendResult;
    }
    resendError = resendResult.error;
    console.warn(
      `⚠️ Resend delivery failed for ${toEmail} (${resendResult.error}). Falling back to SMTP...`
    );
  }

  // 2. Fallback to database SMTP configuration
  const config = await getActiveEmailConfig();

  if (!config || !config.isConfigured) {
    console.warn(
      `⚠️ [EMAIL_SERVICE] Neither Resend succeeded nor SMTP configured for recipient domain.`
    );
    return {
      success: false,
      error:
        resendError ||
        'Email service is not configured. Please verify your domain in Resend or configure SMTP in Admin Settings.',
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
    <title>Your CricketVerse AI Password Reset Verification Code</title>
  </head>
  <body style="margin: 0; padding: 0; background-color: #0B1118; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; color: #E2E8F0;">
    <table width="100%" border="0" cellspacing="0" cellpadding="0" style="background-color: #0B1118; padding: 36px 12px;">
      <tr>
        <td align="center">
          <table width="100%" border="0" cellspacing="0" cellpadding="0" style="max-width: 480px; background-color: #101927; border-radius: 16px; border: 1px solid rgba(255,255,255,0.12); box-shadow: 0 4px 20px rgba(0, 0, 0, 0.4); overflow: hidden;">
            
            <!-- Brand Header -->
            <tr>
              <td style="padding: 28px 24px 20px 24px; text-align: center; border-bottom: 1px solid rgba(255,255,255,0.08);">
                <div style="display: inline-block; padding: 6px 16px; border-radius: 10px; background: linear-gradient(135deg, #00E5FF, #00E676);">
                  <span style="font-size: 16px; font-weight: 800; color: #0B1118; letter-spacing: 1.2px;">⚡ CRICKETVERSE AI</span>
                </div>
                <h2 style="margin: 14px 0 0 0; font-size: 20px; font-weight: 700; color: #ffffff;">Password Reset Code</h2>
              </td>
            </tr>

            <!-- Focused Content -->
            <tr>
              <td style="padding: 28px 24px; text-align: center;">
                <p style="margin: 0 0 6px 0; font-size: 15px; font-weight: 600; color: #cbd5e1;">
                  Hello ${displayName},
                </p>
                <p style="margin: 0 0 18px 0; font-size: 14px; color: #94a3b8; line-height: 1.5;">
                  Here is your verification code to reset your CricketVerse AI password:
                </p>

                <!-- Focused OTP Box -->
                <div style="background-color: #0B1118; border: 2px dashed #00E5FF; border-radius: 14px; padding: 18px 12px; margin: 16px 0; text-align: center;">
                  <div style="font-size: 38px; font-weight: 900; letter-spacing: 8px; color: #00E676; font-family: monospace; line-height: 1.2;">
                    ${otpCode}
                  </div>
                  <div style="font-size: 12.5px; font-weight: 600; color: #00E5FF; margin-top: 8px;">
                    ⏱️ Code expires in 5 minutes
                  </div>
                </div>

                <p style="margin: 18px 0 0 0; font-size: 12.5px; color: #94a3b8; line-height: 1.5;">
                  If you didn't request a password reset, you can safely ignore this email.
                </p>
              </td>
            </tr>

            <!-- Footer -->
            <tr>
              <td style="padding: 16px 24px; background-color: #0B1118; border-top: 1px solid rgba(255,255,255,0.08); text-align: center; font-size: 11.5px; color: #64748b;">
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
    console.log(`[EMAIL_SERVICE] Attempting SMTP delivery via ${config.host}:${config.port} (IPv4)`);
    const info = await transporter.sendMail({
      from: `"${config.senderName}" <${config.senderEmail}>`,
      to: toEmail,
      subject: `Your CricketVerse AI Password Reset Verification Code`,
      text: `Hello ${displayName},\n\nYour CricketVerse AI password reset OTP is: ${otpCode}\n\nValid for 5 minutes. If you did not request this, please ignore this email.\n\nCricketVerse AI Team`,
      html: htmlContent,
    });

    console.log(`✅ [EMAIL_SERVICE] Password reset OTP email sent via SMTP. MessageId: ${info.messageId}`);
    return { success: true, messageId: info.messageId };
  } catch (sendErr: any) {
    console.error(`❌ [EMAIL_SERVICE] SMTP delivery error on port ${config.port}:`, sendErr?.message || sendErr);

    // Fallback to STARTTLS port 587 if port 465 timed out or failed on cloud network
    if (config.port === 465 && config.host.toLowerCase().includes('gmail')) {
      try {
        console.log('[EMAIL_SERVICE] Retrying SMTP delivery via smtp.gmail.com:587 (STARTTLS)...');
        const fallbackTransporter = createTransporter({
          ...config,
          port: 587,
          secure: false,
        });
        const info587 = await fallbackTransporter.sendMail({
          from: `"${config.senderName}" <${config.senderEmail}>`,
          to: toEmail,
          subject: `Your CricketVerse AI Password Reset Verification Code`,
          text: `Hello ${displayName},\n\nYour CricketVerse AI password reset OTP is: ${otpCode}\n\nValid for 5 minutes. If you did not request this, please ignore this email.\n\nCricketVerse AI Team`,
          html: htmlContent,
        });
        console.log(`✅ [EMAIL_SERVICE] OTP sent via port 587 STARTTLS. MessageId: ${info587.messageId}`);
        return { success: true, messageId: info587.messageId };
      } catch (err587: any) {
        console.error('❌ [EMAIL_SERVICE] Port 587 STARTTLS fallback also failed:', err587?.message || err587);
        return {
          success: false,
          error: resendError
            ? `Resend rejected recipient (${resendError}) and cloud SMTP fallback timed out.`
            : err587?.message || sendErr?.message || 'Failed to deliver OTP email.',
        };
      }
    }

    return {
      success: false,
      error: resendError
        ? `Resend rejected recipient (${resendError}) and SMTP failed (${sendErr?.message || 'error'}).`
        : sendErr?.message || 'Failed to send email.',
    };
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
