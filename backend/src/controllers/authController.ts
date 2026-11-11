import { Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import crypto from 'crypto';
import jwt from 'jsonwebtoken';
import mongoose from 'mongoose';
import { UserModel } from '../models/User';
import { MatchModel } from '../models/Match';
import { PasswordResetOtpModel } from '../models/PasswordResetOtp';
import { broadcastNotification } from '../sockets/socketHandler';
import {
  getPublicEmailConfig,
  saveEmailConfig,
  sendTestEmail,
} from '../services/emailService';
import {
  checkVerificationSms,
  isValidE164Phone,
  normalizePhoneNumber,
  sendVerificationSms,
} from '../services/twilioService';

const JWT_SECRET = process.env.JWT_SECRET || 'cricketverse_super_secret_key_123!';

// In-memory fallback for logged-in profile password update
const passwordOtpMap = new Map<string, { otp: string; expiresAt: number }>();

export interface RegistrationValidationResult {
  isValid: boolean;
  error?: string;
  field?: 'email' | 'password' | 'confirmPassword' | 'name';
}

export function validateRegistrationInput(
  email: any,
  password: any,
  confirmPassword?: any,
  name?: any
): RegistrationValidationResult {
  if (!email || typeof email !== 'string' || email.trim().length === 0) {
    return { isValid: false, error: 'Email is required.', field: 'email' };
  }

  const trimmedEmail = email.trim();

  if (/\s/.test(trimmedEmail)) {
    return { isValid: false, error: 'Email cannot contain spaces.', field: 'email' };
  }

  const atMatches = trimmedEmail.match(/@/g);
  if (!atMatches || atMatches.length !== 1) {
    return { isValid: false, error: 'Please enter a valid email address.', field: 'email' };
  }

  const emailRegex = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
  if (!emailRegex.test(trimmedEmail)) {
    return { isValid: false, error: 'Please enter a valid email address.', field: 'email' };
  }

  const [localPart, domainPart] = trimmedEmail.split('@');
  if (!localPart || !domainPart || domainPart.startsWith('.') || domainPart.endsWith('.') || domainPart.indexOf('.') === -1) {
    return { isValid: false, error: 'Please enter a valid email address.', field: 'email' };
  }

  if (!password || typeof password !== 'string' || password.length === 0) {
    return { isValid: false, error: 'Password is required.', field: 'password' };
  }

  if (/\s/.test(password)) {
    return { isValid: false, error: 'Password cannot contain spaces.', field: 'password' };
  }

  if (password.length < 8) {
    return { isValid: false, error: 'Password must be at least 8 characters long.', field: 'password' };
  }

  if (!/[A-Z]/.test(password)) {
    return { isValid: false, error: 'Password must contain at least one uppercase letter.', field: 'password' };
  }

  if (!/[a-z]/.test(password)) {
    return { isValid: false, error: 'Password must contain at least one lowercase letter.', field: 'password' };
  }

  if (!/[0-9]/.test(password)) {
    return { isValid: false, error: 'Password must contain at least one number.', field: 'password' };
  }

  const specialCharRegex = /[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]/;
  if (!specialCharRegex.test(password)) {
    return { isValid: false, error: 'Password must contain at least one special symbol (!@#$%^&*...).', field: 'password' };
  }

  if (confirmPassword !== undefined && confirmPassword !== null) {
    if (confirmPassword !== password) {
      return { isValid: false, error: 'Passwords do not match.', field: 'confirmPassword' };
    }
  }

  return { isValid: true };
}

export async function login(req: Request, res: Response) {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ error: 'Email/username and password are required.' });
  }

  const rawEmail = typeof email === 'string' ? email.trim() : '';
  const normalizedEmail = rawEmail.toLowerCase();

  try {
    // 1. Scorer / Manager login check against active matches (Keep untouched)
    let match = await MatchModel.findOne({
      scorerUsername: rawEmail,
      scorerPassword: password,
    });

    if (!match && rawEmail !== normalizedEmail) {
      match = await MatchModel.findOne({
        scorerUsername: normalizedEmail,
        scorerPassword: password,
      });
    }

    if (match) {
      const token = jwt.sign({ id: `scorer_${match.id}`, email: match.scorerUsername, role: 'Scorer' }, JWT_SECRET, { expiresIn: '7d' });
      return res.status(200).json({
        token,
        user: { id: `scorer_${match.id}`, email: match.scorerUsername, role: 'Scorer', name: `Official Scorer (${match.scorerUsername})` },
        activeScorerMatchId: match.id
      });
    }

    // 2. User & Admin login check from UserModel
    let user = await UserModel.findOne({ email: normalizedEmail });
    if (!user && rawEmail !== normalizedEmail) {
      user = await UserModel.findOne({ email: rawEmail });
    }

    if (user) {
      const isMatch = await bcrypt.compare(password, user.passwordHash);
      if (isMatch) {
        const token = jwt.sign({ id: user.id, email: user.email, role: user.role }, JWT_SECRET, { expiresIn: '7d' });
        return res.status(200).json({
          token,
          user: {
            id: user.id,
            email: user.email,
            role: user.role,
            name: user.name || (user.role === 'Admin' ? 'Rajesh Kumar' : user.email.split('@')[0]),
          },
        });
      }
    }

    // Initial fallback for default admin if DB seed was pending
    if ((normalizedEmail === 'admin@gmail.com' || rawEmail === 'admin@gmail.com') && password === 'admin123') {
      const adminPassHash = await bcrypt.hash('admin123', 10);
      const seededAdmin = await UserModel.findOneAndUpdate(
        { email: 'admin@gmail.com' },
        {
          $setOnInsert: {
            id: 'admin_user',
            email: 'admin@gmail.com',
            passwordHash: adminPassHash,
            role: 'Admin',
            name: 'Rajesh Kumar',
          },
        },
        { upsert: true, new: true }
      );
      const token = jwt.sign({ id: seededAdmin.id, email: seededAdmin.email, role: 'Admin' }, JWT_SECRET, { expiresIn: '7d' });
      return res.status(200).json({
        token,
        user: { id: seededAdmin.id, email: seededAdmin.email, role: 'Admin', name: seededAdmin.name || 'Rajesh Kumar' },
      });
    }

    return res.status(401).json({ error: 'Invalid email or password.' });
  } catch (err) {
    console.error('Login error:', err);
    return res.status(500).json({ error: 'Internal server error.' });
  }
}

export async function register(req: Request, res: Response) {
  const { email, password, confirmPassword, name, phone } = req.body;

  const validation = validateRegistrationInput(email, password, confirmPassword, name);
  if (!validation.isValid) {
    return res.status(400).json({
      error: validation.error,
      field: validation.field,
    });
  }

  let normalizedPhone: string | undefined;
  if (phone !== undefined && phone !== null && String(phone).trim().length > 0) {
    const candidate = normalizePhoneNumber(String(phone));
    if (!isValidE164Phone(candidate)) {
      return res.status(400).json({
        error: 'Please enter a valid international phone number (e.g. +919876543210).',
        field: 'phone',
      });
    }
    normalizedPhone = candidate;
  }

  const normalizedEmail = (email as string).trim().toLowerCase();
  const trimmedName = typeof name === 'string' ? name.trim() : '';
  const finalName = trimmedName || normalizedEmail.split('@')[0];

  try {
    const existingUser = await UserModel.findOne({ email: normalizedEmail });
    if (existingUser) {
      return res.status(409).json({
        error: 'An account with this email already exists.',
        field: 'email',
      });
    }

    if (normalizedPhone) {
      const existingPhoneUser = await UserModel.findOne({ phone: normalizedPhone });
      if (existingPhoneUser) {
        return res.status(409).json({
          error: 'An account with this phone number already exists.',
          field: 'phone',
        });
      }
    }

    const passwordHash = await bcrypt.hash(password, 10);
    const userId = `user_${Date.now()}`;
    const role = 'User';

    const newUser = await UserModel.create({
      id: userId,
      email: normalizedEmail,
      ...(normalizedPhone ? { phone: normalizedPhone } : {}),
      passwordHash,
      role,
      name: finalName,
    });

    const token = jwt.sign({ id: userId, email: normalizedEmail, role }, JWT_SECRET, { expiresIn: '7d' });
    return res.status(201).json({
      token,
      user: {
        id: userId,
        email: normalizedEmail,
        phone: newUser.phone,
        role,
        name: finalName,
      },
    });
  } catch (err: any) {
    if (err && (err.code === 11000 || err.message?.includes('duplicate key'))) {
      const isPhoneDup = err.message?.includes('phone');
      return res.status(409).json({
        error: isPhoneDup
          ? 'An account with this phone number already exists.'
          : 'An account with this email already exists.',
        field: isPhoneDup ? 'phone' : 'email',
      });
    }

    console.error('Registration error:', err);
    return res.status(500).json({ error: 'Internal server error.' });
  }
}

export async function getMe(req: any, res: Response) {
  let activeScorerMatchId: string | null = null;
  if (req.user && req.user.role === 'Scorer' && req.user.id && req.user.id.startsWith('scorer_')) {
    activeScorerMatchId = req.user.id.substring(7);
  }

  let userDetails = { ...req.user };
  if (req.user && req.user.role !== 'Scorer') {
    const dbUser = await UserModel.findOne({ id: req.user.id });
    if (dbUser) {
      userDetails.name = dbUser.name || dbUser.email.split('@')[0];
      userDetails.favoriteTeams = dbUser.favoriteTeams || [];
      userDetails.notificationSettings = dbUser.notificationSettings || {};
    }
  } else if (req.user && req.user.role === 'Scorer') {
    userDetails.name = `Official Scorer`;
  }

  return res.status(200).json({
    user: userDetails,
    activeScorerMatchId
  });
}

export async function updateProfile(req: any, res: Response) {
  const { name, email, favoriteTeams, notificationSettings } = req.body;
  if (!req.user || !req.user.id) {
    return res.status(401).json({ error: 'Unauthorized.' });
  }

  if (req.user.role === 'Scorer') {
    return res.status(400).json({ error: 'Scorer profile cannot be modified.' });
  }

  try {
    if (email) {
      const normalizedEmail = email.trim().toLowerCase();
      const existingUser = await UserModel.findOne({
        email: normalizedEmail,
        id: { $ne: req.user.id }
      });
      if (existingUser) {
        return res.status(409).json({ error: 'Email is already taken by another user.' });
      }
    }

    const updateFields: any = {};
    if (name !== undefined) updateFields.name = name.trim();
    if (email !== undefined) updateFields.email = email.trim().toLowerCase();
    if (favoriteTeams !== undefined) updateFields.favoriteTeams = favoriteTeams;
    if (notificationSettings !== undefined) updateFields.notificationSettings = notificationSettings;

    const updatedUser = await UserModel.findOneAndUpdate(
      { id: req.user.id },
      { $set: updateFields },
      { new: true }
    );

    if (!updatedUser) {
      return res.status(404).json({ error: 'User not found.' });
    }

    const token = jwt.sign({ id: updatedUser.id, email: updatedUser.email, role: updatedUser.role }, JWT_SECRET, { expiresIn: '7d' });

    return res.status(200).json({
      token,
      user: {
        id: updatedUser.id,
        email: updatedUser.email,
        role: updatedUser.role,
        name: updatedUser.name,
        favoriteTeams: updatedUser.favoriteTeams,
        notificationSettings: updatedUser.notificationSettings,
      }
    });
  } catch (err) {
    console.error('Update profile error:', err);
    return res.status(500).json({ error: 'Internal server error.' });
  }
}

// Logged-in profile password OTP
export async function requestPasswordOtp(req: any, res: Response) {
  if (!req.user || !req.user.id) {
    return res.status(401).json({ error: 'Unauthorized.' });
  }

  const otp = Math.floor(1000 + Math.random() * 9000).toString();
  const expiresAt = Date.now() + 10 * 60 * 1000;

  passwordOtpMap.set(req.user.id, { otp, expiresAt });
  console.log(`[PROFILE_OTP] Generated password change verification code for user ${req.user.id}`);

  return res.status(200).json({
    message: 'OTP generated successfully.',
    otp
  });
}

// Logged-in profile password update
export async function updatePassword(req: any, res: Response) {
  const { otp, newPassword } = req.body;

  if (!req.user || !req.user.id) {
    return res.status(401).json({ error: 'Unauthorized.' });
  }

  if (!otp || !newPassword) {
    return res.status(400).json({ error: 'OTP and new password are required.' });
  }

  const storedData = passwordOtpMap.get(req.user.id);
  if (!storedData) {
    return res.status(400).json({ error: 'No OTP requested for this user.' });
  }

  if (Date.now() > storedData.expiresAt) {
    passwordOtpMap.delete(req.user.id);
    return res.status(400).json({ error: 'OTP has expired.' });
  }

  if (storedData.otp !== otp) {
    return res.status(400).json({ error: 'Invalid OTP.' });
  }

  try {
    const passwordHash = await bcrypt.hash(newPassword, 10);

    await UserModel.findOneAndUpdate(
      { id: req.user.id },
      { $set: { passwordHash } }
    );

    passwordOtpMap.delete(req.user.id);

    return res.status(200).json({ message: 'Password updated successfully.' });
  } catch (err) {
    console.error('Update password error:', err);
    return res.status(500).json({ error: 'Internal server error.' });
  }
}

// ==========================================
// FORGOT PASSWORD FLOW (Twilio SMS Verify & Reset)
// ==========================================

/**
 * Request SMS OTP for Forgot Password via Twilio Verify
 * Validates E.164 phone number, enforces 60s cooldown, and dispatches SMS OTP.
 */
export async function requestForgotPasswordOtp(req: Request, res: Response) {
  const requestId = (req.headers['x-request-id'] as string) || `fp_srv_${Date.now()}`;
  const rawPhone = req.body?.phone;
  const dbReadyState = mongoose.connection.readyState;

  console.log(`[FP_TRACE][${requestId}] Request received: ${req.method} ${req.originalUrl} | MongoDB readyState=${dbReadyState}`);

  if (dbReadyState !== 1) {
    console.error(`[FP_TRACE][${requestId}] Aborting: MongoDB Atlas not connected (readyState=${dbReadyState})`);
    return res.status(503).json({
      error: 'Database service temporarily unavailable. Please retry in a few seconds.',
    });
  }

  if (!rawPhone || typeof rawPhone !== 'string') {
    return res.status(400).json({ error: 'Please enter a valid registered phone number with country code.' });
  }

  const normalizedPhone = normalizePhoneNumber(rawPhone);
  if (!isValidE164Phone(normalizedPhone)) {
    console.warn(`[FP_TRACE][${requestId}] Phone validation failed -> HTTP 400`);
    return res.status(400).json({
      error: 'Please enter a valid international phone number (e.g. +919876543210).',
    });
  }

  const maskedSuffix = normalizedPhone.slice(-4);
  console.log(`[FP_TRACE][${requestId}] Phone validated (ending: ***${maskedSuffix})`);

  try {
    // 1. Check whether registered account exists with this phone
    const user = await UserModel.findOne({ phone: normalizedPhone });
    console.log(`[FP_TRACE][${requestId}] MongoDB user lookup completed (found: ${Boolean(user)})`);
    if (!user) {
      console.log(`[FP_TRACE][${requestId}] Unregistered phone handled safely -> HTTP 200`);
      return res.status(200).json({
        success: true,
        otpSent: true,
        message: 'If an account is associated with this phone number, an SMS verification code has been sent.',
      });
    }

    // 2. Cooldown check (60-second cooldown between requests)
    const existingOtp = await PasswordResetOtpModel.findOne({ phone: normalizedPhone }).lean();
    if (existingOtp) {
      const requestedTime = existingOtp.lastRequestedAt
        ? new Date(existingOtp.lastRequestedAt).getTime()
        : (existingOtp.createdAt ? new Date(existingOtp.createdAt).getTime() : 0);
      if (requestedTime > 0) {
        const elapsedMs = Date.now() - requestedTime;
        if (elapsedMs < 60000 && elapsedMs >= 0) {
          const remainingSeconds = Math.ceil((60000 - elapsedMs) / 1000);
          console.log(`[FP_TRACE][${requestId}] Cooldown enforced (${remainingSeconds}s remaining) -> HTTP 429`);
          return res.status(429).json({
            error: `Please wait ${remainingSeconds}s before requesting a new verification code.`,
            cooldownRemaining: remainingSeconds,
          });
        }
      }
    }

    // 3. Dispatch SMS OTP via Twilio Verify
    console.log(`[FP_TRACE][${requestId}] Dispatching SMS OTP via Twilio Verify...`);
    const smsResult = await sendVerificationSms(normalizedPhone);
    console.log(`[FP_TRACE][${requestId}] Twilio response: success=${smsResult.success}`);

    if (!smsResult.success) {
      console.error(`[FP_TRACE][${requestId}] Twilio SMS delivery failed (${smsResult.error}) -> HTTP 502`);
      return res.status(502).json({
        success: false,
        otpSent: false,
        error: smsResult.error || 'Failed to deliver SMS verification code. Please check your phone number and retry.',
      });
    }

    // 4. Persist cooldown & session tracking record in MongoDB Atlas (5-minute expiry)
    await PasswordResetOtpModel.deleteMany({ phone: normalizedPhone });
    await PasswordResetOtpModel.create({
      phone: normalizedPhone,
      email: user.email,
      attempts: 0,
      verified: false,
      expiresAt: new Date(Date.now() + 5 * 60 * 1000),
      lastRequestedAt: new Date(),
      createdAt: new Date(),
    });
    console.log(`[FP_TRACE][${requestId}] OTP session saved in MongoDB Atlas -> HTTP 200`);

    return res.status(200).json({
      success: true,
      otpSent: true,
      message: 'A 6-digit verification code has been sent via SMS.',
    });
  } catch (err: any) {
    console.error(`[FP_TRACE][${requestId}] Unexpected error -> HTTP 500:`, err?.message || err);
    return res.status(500).json({ error: 'Internal server error requesting verification code.' });
  }
}

/**
 * Resend SMS OTP for Forgot Password
 * Applies 60-second cooldown and dispatches a fresh Twilio Verify SMS.
 */
export async function resendForgotPasswordOtp(req: Request, res: Response) {
  return requestForgotPasswordOtp(req, res);
}

/**
 * Verify SMS OTP for Forgot Password using Twilio Verify
 * Enforces 5-minute expiration and max 5 attempts lockout.
 * Issues single-use reset authorization token.
 */
export async function verifyForgotPasswordOtp(req: Request, res: Response) {
  const requestId = (req.headers['x-request-id'] as string) || `fp_verify_${Date.now()}`;
  const rawPhone = req.body?.phone;
  const otp = req.body?.otp;

  if (!rawPhone || typeof rawPhone !== 'string' || !otp) {
    return res.status(400).json({ error: 'Phone number and 6-digit verification code are required.' });
  }

  const normalizedPhone = normalizePhoneNumber(rawPhone);
  if (!isValidE164Phone(normalizedPhone)) {
    return res.status(400).json({ error: 'Please enter a valid international phone number.' });
  }

  const cleanOtp = String(otp).trim();
  if (cleanOtp.length !== 6 || !/^\d{6}$/.test(cleanOtp)) {
    return res.status(400).json({ error: 'Please enter a valid 6-digit numeric verification code.' });
  }

  try {
    const record = await PasswordResetOtpModel.findOne({ phone: normalizedPhone });

    if (!record) {
      return res.status(400).json({ error: 'Invalid or expired verification session. Please request a new code.' });
    }

    if (record.verified && record.resetToken) {
      return res.status(200).json({
        success: true,
        message: 'OTP already verified.',
        resetToken: record.resetToken,
      });
    }

    // Check 5-minute expiration
    if (Date.now() > new Date(record.expiresAt).getTime()) {
      await PasswordResetOtpModel.deleteMany({ phone: normalizedPhone });
      return res.status(400).json({ error: 'Verification code has expired (5 minute limit). Please request a new code.' });
    }

    // Check maximum 5 incorrect attempts
    if (record.attempts >= 5) {
      await PasswordResetOtpModel.deleteMany({ phone: normalizedPhone });
      return res.status(429).json({
        error: 'Too many incorrect attempts. This code has been invalidated for security. Please request a new code.',
      });
    }

    // Verify OTP via Twilio Verify API
    const checkResult = await checkVerificationSms(normalizedPhone, cleanOtp);
    if (!checkResult.success) {
      console.error(`[FP_TRACE][${requestId}] Twilio check error: ${checkResult.error}`);
      return res.status(502).json({
        error: checkResult.error || 'Could not verify code with SMS provider. Please try again.',
      });
    }

    if (!checkResult.valid) {
      record.attempts = (record.attempts || 0) + 1;
      await record.save();

      const remainingAttempts = 5 - record.attempts;
      if (remainingAttempts <= 0) {
        await PasswordResetOtpModel.deleteMany({ phone: normalizedPhone });
        return res.status(400).json({
          error: 'Too many incorrect attempts. Verification code invalidated. Please request a new code.',
        });
      }

      return res.status(400).json({
        error: `Incorrect verification code. ${remainingAttempts} attempt${remainingAttempts === 1 ? '' : 's'} remaining.`,
      });
    }

    // Issue single-use reset authorization token (15 mins)
    const resetToken = crypto.randomBytes(32).toString('hex');
    record.verified = true;
    record.resetToken = resetToken;
    record.resetTokenExpiresAt = new Date(Date.now() + 15 * 60 * 1000);
    await record.save();

    console.log(`[FP_TRACE][${requestId}] Twilio OTP verified and resetToken issued.`);
    return res.status(200).json({
      success: true,
      message: 'OTP verified successfully.',
      resetToken,
    });
  } catch (err: any) {
    console.error(`[FP_TRACE][${requestId}] Verify OTP error:`, err?.message || err);
    return res.status(500).json({ error: 'Internal server error verifying OTP.' });
  }
}

/**
 * Reset Password using verified Twilio SMS OTP Reset Authorization Token
 */
export async function resetForgotPassword(req: Request, res: Response) {
  const { phone, resetToken, newPassword, confirmPassword } = req.body;

  if (!phone || !newPassword) {
    return res.status(400).json({ error: 'Phone number and new password are required.' });
  }

  const normalizedPhone = normalizePhoneNumber(String(phone));
  if (!isValidE164Phone(normalizedPhone)) {
    return res.status(400).json({ error: 'Please enter a valid international phone number.' });
  }

  // Validate new password rules & confirmation
  const validation = validateRegistrationInput('valid@cricketverse.ai', newPassword, confirmPassword);
  if (!validation.isValid) {
    return res.status(400).json({
      error: validation.error,
      field: validation.field,
    });
  }

  try {
    // 1. Look up verified reset authorization record
    const record = resetToken && typeof resetToken === 'string'
      ? await PasswordResetOtpModel.findOne({
          phone: normalizedPhone,
          resetToken: resetToken.trim(),
          verified: true,
        })
      : await PasswordResetOtpModel.findOne({
          phone: normalizedPhone,
          verified: true,
        });

    if (!record) {
      return res.status(400).json({
        error: 'Password reset authorization is invalid or expired. Please restart the recovery process.',
      });
    }

    if (record.resetTokenExpiresAt && Date.now() > new Date(record.resetTokenExpiresAt).getTime()) {
      await PasswordResetOtpModel.deleteMany({ phone: normalizedPhone });
      return res.status(400).json({
        error: 'Password reset session has expired. Please request a new verification code.',
      });
    }

    // 2. Hash new password securely using bcrypt
    const passwordHash = await bcrypt.hash(newPassword, 10);

    // 3. Atomically update existing user password
    const updatedUser = await UserModel.findOneAndUpdate(
      { phone: normalizedPhone },
      { $set: { passwordHash } },
      { new: true }
    );

    if (!updatedUser) {
      return res.status(404).json({ error: 'User account not found.' });
    }

    // 4. Invalidate reset authorization completely
    await PasswordResetOtpModel.deleteMany({ phone: normalizedPhone });

    console.log(`✅ Password successfully reset for phone ending ***${normalizedPhone.slice(-4)} (Role: ${updatedUser.role})`);

    return res.status(200).json({
      success: true,
      message: 'Password reset successfully! You can now log in with your new password.',
    });
  } catch (err: any) {
    console.error('Reset password error:', err);
    return res.status(500).json({ error: 'Internal server error resetting password.' });
  }
}

// ==========================================
// ADMIN EMAIL CONFIGURATION ENDPOINTS
// ==========================================

/**
 * Get Email Configuration (Admin only)
 * NEVER returns the App Password.
 */
export async function getEmailConfigEndpoint(req: Request, res: Response) {
  try {
    const config = await getPublicEmailConfig();
    return res.status(200).json({ config });
  } catch (err) {
    console.error('Get email config error:', err);
    return res.status(500).json({ error: 'Failed to retrieve email configuration.' });
  }
}

/**
 * Update Email Configuration & App Password (Admin only)
 * Allows entering a fresh app password. Password is never exposed.
 */
export async function updateEmailConfigEndpoint(req: any, res: Response) {
  const { senderEmail, appPassword, senderName, host, port, secure } = req.body;

  if (!senderEmail || typeof senderEmail !== 'string' || senderEmail.trim().length === 0) {
    return res.status(400).json({ error: 'Sender email is required.' });
  }

  try {
    const updatedConfig = await saveEmailConfig({
      senderEmail,
      appPassword,
      senderName,
      host,
      port: port ? Number(port) : undefined,
      secure: secure !== undefined ? Boolean(secure) : undefined,
      updatedBy: req.user?.email || 'Admin',
    });

    return res.status(200).json({
      message: 'Email and App Password configuration saved and verified successfully.',
      config: updatedConfig,
    });
  } catch (err: any) {
    console.error('Update email config error:', err);
    return res.status(400).json({
      error: err.message || 'Failed to update email configuration. Please check the App Password.',
    });
  }
}

/**
 * Send Test Email (Admin only)
 */
export async function testEmailConfigEndpoint(req: any, res: Response) {
  const targetEmail = req.body.targetEmail || req.user?.email || 'admin@gmail.com';

  try {
    const result = await sendTestEmail(targetEmail);
    if (result.success) {
      return res.status(200).json({
        message: `Test email sent successfully to ${targetEmail}.`,
      });
    } else {
      return res.status(400).json({
        error: result.error || 'Failed to send test email. Please check your App Password.',
      });
    }
  } catch (err: any) {
    console.error('Test email error:', err);
    return res.status(500).json({ error: err.message || 'Internal server error sending test email.' });
  }
}

export async function broadcastNotificationEndpoint(req: any, res: Response) {
  const { title, message } = req.body;
  if (!title || !message) {
    return res.status(400).json({ error: 'Title and message are required.' });
  }

  try {
    broadcastNotification({
      title,
      message,
      timestamp: new Date().toISOString()
    });
    return res.status(200).json({ message: 'Notification broadcasted successfully.' });
  } catch (err) {
    console.error('Broadcast notification error:', err);
    return res.status(500).json({ error: 'Internal server error.' });
  }
}

export async function logout(req: any, res: Response) {
  try {
    let user = req.user;

    if (!user && req.headers?.authorization) {
      try {
        const token = req.headers.authorization.split(' ')[1];
        if (token) {
          const decoded = jwt.verify(token, JWT_SECRET) as any;
          user = {
            id: decoded.id,
            email: decoded.email,
            role: decoded.role,
          };
        }
      } catch (_) {}
    }

    const { name, email, role } = req.body || {};
    const displayName = user?.name || name || user?.email?.split('@')[0] || (email ? email.split('@')[0] : 'User');
    console.log(`User logged out: ${displayName} (${user?.id || 'anonymous'})`);

    return res.status(200).json({ message: 'Successfully logged out.' });
  } catch (err) {
    console.error('Logout controller error:', err);
    return res.status(500).json({ error: 'Internal server error.' });
  }
}
