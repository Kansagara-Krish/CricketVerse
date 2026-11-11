import twilio from 'twilio';

function getTwilioConfig() {
  const accountSid = process.env.TWILIO_ACCOUNT_SID?.trim() || '';
  const authToken = process.env.TWILIO_AUTH_TOKEN?.trim() || '';
  const verifyServiceSid = process.env.TWILIO_VERIFY_SERVICE_SID?.trim() || '';
  return { accountSid, authToken, verifyServiceSid };
}

/**
 * Validates whether a phone number is in strict E.164 format (e.g. +919876543210).
 */
export function isValidE164Phone(phone: string): boolean {
  const cleaned = phone.trim();
  return /^\+[1-9]\d{6,14}$/.test(cleaned);
}

/**
 * Normalizes a phone string into trimmed E.164 format if prefixed with +.
 */
export function normalizePhoneNumber(phone: string): string {
  return phone.replace(/[\s\-()]/g, '').trim();
}

/**
 * Logs safe startup diagnostics for Twilio Verify configuration without leaking secrets.
 */
export function logTwilioStartupDiagnostics(): void {
  const { accountSid, authToken, verifyServiceSid } = getTwilioConfig();
  console.log('📱 OTP Provider: TWILIO VERIFY (SMS)');
  console.log(`   TWILIO_ACCOUNT_SID configured: ${Boolean(accountSid)}`);
  console.log(`   TWILIO_AUTH_TOKEN configured: ${Boolean(authToken)}`);
  console.log(`   TWILIO_VERIFY_SERVICE_SID configured: ${Boolean(verifyServiceSid)}`);
}

/**
 * Sends a verification SMS via Twilio Verify API.
 */
export async function sendVerificationSms(
  phoneE164: string
): Promise<{ success: boolean; status?: string; sid?: string; error?: string }> {
  const { accountSid, authToken, verifyServiceSid } = getTwilioConfig();

  if (!accountSid || !authToken || !verifyServiceSid) {
    return {
      success: false,
      error: 'Twilio Verify is not configured on the server (missing TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN, or TWILIO_VERIFY_SERVICE_SID).',
    };
  }

  try {
    const client = twilio(accountSid, authToken);
    const verification = await client.verify.v2
      .services(verifyServiceSid)
      .verifications.create({
        to: phoneE164,
        channel: 'sms',
      });

    console.log(`[TWILIO_VERIFY] Verification SMS submitted. status=${verification.status}`);
    return {
      success: true,
      status: verification.status,
      sid: verification.sid,
    };
  } catch (err: any) {
    console.error('❌ [TWILIO_VERIFY] Failed to send verification SMS:', err?.message || err);
    return {
      success: false,
      error: err?.message || 'Twilio failed to send SMS verification code.',
    };
  }
}

/**
 * Verifies a user-submitted 6-digit SMS OTP code against Twilio Verify.
 */
export async function checkVerificationSms(
  phoneE164: string,
  code: string
): Promise<{ success: boolean; valid: boolean; status?: string; error?: string }> {
  const { accountSid, authToken, verifyServiceSid } = getTwilioConfig();

  if (!accountSid || !authToken || !verifyServiceSid) {
    return {
      success: false,
      valid: false,
      error: 'Twilio Verify is not configured on the server.',
    };
  }

  try {
    const client = twilio(accountSid, authToken);
    const check = await client.verify.v2
      .services(verifyServiceSid)
      .verificationChecks.create({
        to: phoneE164,
        code: code.trim(),
      });

    const isApproved = check.status === 'approved';
    console.log(`[TWILIO_VERIFY] Code check completed. status=${check.status}, approved=${isApproved}`);

    return {
      success: true,
      valid: isApproved,
      status: check.status,
    };
  } catch (err: any) {
    console.error('❌ [TWILIO_VERIFY] Failed to check verification code:', err?.message || err);
    return {
      success: false,
      valid: false,
      error: err?.message || 'Verification code check failed.',
    };
  }
}

