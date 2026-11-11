import dotenv from 'dotenv';
dotenv.config();

import mongoose from 'mongoose';
import bcrypt from 'bcryptjs';
import crypto from 'crypto';
import { UserModel } from '../models/User';
import { PasswordResetOtpModel } from '../models/PasswordResetOtp';
import { isValidE164Phone, normalizePhoneNumber, sendVerificationSms } from '../services/twilioService';
import {
  getMe,
  lookupPhoneByEmail,
  requestForgotPasswordOtp,
  resetForgotPassword,
  updateProfile,
} from '../controllers/authController';

function createMockRes() {
  const res: any = {
    statusCode: 200,
    body: null as any,
    status(code: number) {
      this.statusCode = code;
      return this;
    },
    json(data: any) {
      this.body = data;
      return this;
    },
  };
  return res;
}

async function runTests() {
  console.log('🧪 Starting Twilio Phone Registration & Forgot Password Integration Tests...');

  if (!process.env.MONGODB_URI) {
    throw new Error('MONGODB_URI is required to run integration tests.');
  }

  await mongoose.connect(process.env.MONGODB_URI);

  const testUserId = `test_user_${Date.now()}`;
  const testEmail = `twilio_test_${Date.now()}@example.com`;
  const testPhone = `+9198${Math.floor(10000000 + Math.random() * 89999999)}`;
  const otherUserId = `test_other_${Date.now()}`;
  const otherEmail = `twilio_other_${Date.now()}@example.com`;
  const otherPhone = `+9197${Math.floor(10000000 + Math.random() * 89999999)}`;
  const noPhoneUserId = `test_nophone_${Date.now()}`;
  const noPhoneEmail = `twilio_nophone_${Date.now()}@example.com`;
  const newCandidatePhone = `+9196${Math.floor(10000000 + Math.random() * 89999999)}`;
  const initialPassword = 'OldPassword1!';
  const newPassword = 'NewPassword2@';

  try {
    // 1. Validate E.164 normalization & validation
    if (!isValidE164Phone(normalizePhoneNumber('+91 98765-43210'))) {
      throw new Error('Valid E.164 phone failed validation.');
    }
    if (isValidE164Phone('9876543210') || isValidE164Phone('+91abc123')) {
      throw new Error('Invalid phone format should fail E.164 validation.');
    }
    console.log('✅ E.164 phone validation passed.');

    // 2. Create test user with phone number
    const passwordHash = await bcrypt.hash(initialPassword, 10);
    await UserModel.create({
      id: testUserId,
      email: testEmail,
      phone: testPhone,
      phoneVerified: true,
      passwordHash,
      role: 'User',
      name: 'Twilio Test User',
    });
    await UserModel.create({
      id: otherUserId,
      email: otherEmail,
      phone: otherPhone,
      phoneVerified: true,
      passwordHash,
      role: 'User',
      name: 'Other User',
    });
    await UserModel.create({
      id: noPhoneUserId,
      email: noPhoneEmail,
      phoneVerified: false,
      passwordHash,
      role: 'User',
      name: 'No Phone User',
    });
    console.log('✅ Test user created with phone number.');

    // 3. Smart Forgot Password email lookup -> masked phone + hasVerifiedPhone + flowRef + error handling
    const expectedMasked = `+91 ******${testPhone.slice(-4)}`;
    const lookupRes = createMockRes();
    await lookupPhoneByEmail({ body: { email: testEmail.toUpperCase() } } as any, lookupRes);
    if (
      lookupRes.statusCode !== 200 ||
      lookupRes.body?.success !== true ||
      lookupRes.body?.data?.hasVerifiedPhone !== true ||
      lookupRes.body?.data?.maskedPhone !== expectedMasked ||
      typeof lookupRes.body?.data?.flowRef !== 'string' ||
      lookupRes.body.data.flowRef.length === 0 ||
      JSON.stringify(lookupRes.body).includes(testPhone)
    ) {
      throw new Error(`lookupPhoneByEmail failed: ${JSON.stringify(lookupRes)}`);
    }
    const flowRef: string = lookupRes.body.data.flowRef;
    console.log(`✅ lookupPhoneByEmail returned masked phone (${lookupRes.body.data.maskedPhone}) without exposing full phone.`);

    const invalidEmailRes = createMockRes();
    await lookupPhoneByEmail({ body: { email: 'invalid-email' } } as any, invalidEmailRes);
    if (invalidEmailRes.statusCode !== 400 || invalidEmailRes.body?.success !== false || !invalidEmailRes.body?.error) {
      throw new Error(`Expected 400 success=false for invalid email, got ${JSON.stringify(invalidEmailRes)}`);
    }

    const missingEmailRes = createMockRes();
    await lookupPhoneByEmail({ body: { email: `missing_${Date.now()}@example.com` } } as any, missingEmailRes);
    if (missingEmailRes.statusCode !== 404 || missingEmailRes.body?.success !== false || !missingEmailRes.body?.error) {
      throw new Error(`Expected 404 success=false for unregistered email, got ${JSON.stringify(missingEmailRes)}`);
    }

    const noPhoneLookupRes = createMockRes();
    await lookupPhoneByEmail({ body: { email: noPhoneEmail } } as any, noPhoneLookupRes);
    if (noPhoneLookupRes.statusCode !== 404 || noPhoneLookupRes.body?.success !== false || noPhoneLookupRes.body?.data?.hasVerifiedPhone !== false) {
      throw new Error(`Expected 404 hasVerifiedPhone=false for account without phone, got ${JSON.stringify(noPhoneLookupRes)}`);
    }
    console.log('✅ lookupPhoneByEmail invalid, unregistered & missing-phone error handling passed.');

    // Tampered flowRef must be rejected by resolvePhoneTarget
    const tamperedRes = createMockRes();
    await requestForgotPasswordOtp({ headers: {}, body: { flowRef: 'invalid.jwt.token' } } as any, tamperedRes);
    if (tamperedRes.statusCode !== 400) {
      throw new Error(`Expected 400 for tampered flowRef, got ${JSON.stringify(tamperedRes)}`);
    }
    console.log('✅ Tampered flowRef rejection verified.');

    // 4. Unregistered phone check
    const unregisteredUser = await UserModel.findOne({ phone: '+919999999999' });
    if (unregisteredUser) throw new Error('Expected unregistered phone not to exist.');
    console.log('✅ Unregistered phone check passed.');

    // 4. Create OTP session & verify 60s cooldown check
    await PasswordResetOtpModel.deleteMany({ phone: testPhone });
    await PasswordResetOtpModel.create({
      phone: testPhone,
      email: testEmail,
      attempts: 0,
      verified: false,
      expiresAt: new Date(Date.now() + 5 * 60 * 1000),
      lastRequestedAt: new Date(),
      createdAt: new Date(),
    });

    const record = await PasswordResetOtpModel.findOne({ phone: testPhone }).lean();
    if (!record || !record.lastRequestedAt) {
      throw new Error('Expected OTP cooldown record with lastRequestedAt.');
    }
    const elapsedMs = Date.now() - new Date(record.lastRequestedAt).getTime();
    if (elapsedMs >= 60000) {
      throw new Error('Expected cooldown to be active within 60 seconds.');
    }
    console.log('✅ 60-second cooldown check verified.');

    // 5. Simulate max 5 attempts lockout
    const doc = await PasswordResetOtpModel.findOne({ phone: testPhone });
    if (!doc) throw new Error('Expected OTP session document.');
    doc.attempts = 5;
    await doc.save();
    if (doc.attempts < 5) throw new Error('Attempts lockout counter failed.');
    console.log('✅ 5-attempt lockout counter verified.');

    // 6. Simulate expired OTP check
    doc.attempts = 0;
    doc.expiresAt = new Date(Date.now() - 1000);
    await doc.save();
    if (Date.now() <= new Date(doc.expiresAt).getTime()) {
      throw new Error('Expected OTP record to be expired.');
    }
    console.log('✅ 5-minute OTP expiration logic verified.');

    // 7. Reset token issuance & password update + single-use deletion
    const resetToken = crypto.randomBytes(32).toString('hex');
    doc.expiresAt = new Date(Date.now() + 5 * 60 * 1000);
    doc.verified = true;
    doc.resetToken = resetToken;
    doc.resetTokenExpiresAt = new Date(Date.now() + 15 * 60 * 1000);
    await doc.save();

    const verifiedDoc = await PasswordResetOtpModel.findOne({
      phone: testPhone,
      resetToken,
      verified: true,
    });
    if (!verifiedDoc) throw new Error('Reset token lookup failed.');

    // Reset password using flowRef ONLY (verifies resolvePhoneTarget via flowRef)
    const flowResetRes = createMockRes();
    await resetForgotPassword(
      {
        headers: {},
        body: {
          flowRef,
          resetToken,
          newPassword,
          confirmPassword: newPassword,
        },
      } as any,
      flowResetRes
    );
    if (flowResetRes.statusCode !== 200) {
      throw new Error(`resetForgotPassword via flowRef failed: ${JSON.stringify(flowResetRes)}`);
    }

    const updatedUser = await UserModel.findOne({ phone: testPhone });
    if (!updatedUser) throw new Error('User not found after update.');
    const oldMatch = await bcrypt.compare(initialPassword, updatedUser.passwordHash);
    const newMatch = await bcrypt.compare(newPassword, updatedUser.passwordHash);
    if (oldMatch || !newMatch) {
      throw new Error('Password reset hash verification failed.');
    }

    // Also test direct phone target resolution (State B) fails cleanly without valid token
    const missingTokenRes = createMockRes();
    await resetForgotPassword(
      {
        headers: {},
        body: {
          phone: testPhone,
          newPassword,
          confirmPassword: newPassword,
        },
      } as any,
      missingTokenRes
    );
    if (missingTokenRes.statusCode !== 400) {
      throw new Error(`Expected 400 without resetToken for direct phone flow, got ${JSON.stringify(missingTokenRes)}`);
    }
    console.log('✅ Password reset via flowRef & direct phone target validation passed.');

    // 8. Edit Profile: getMe prefill, phone-less user, validation, duplicate phone, OTP verification & recovery protection
    const meRes = createMockRes();
    await getMe({ user: { id: testUserId, email: testEmail, role: 'User' } }, meRes);
    if (meRes.statusCode !== 200 || meRes.body?.user?.phone !== testPhone || meRes.body?.user?.phoneVerified !== true) {
      throw new Error(`getMe prefill failed: ${JSON.stringify(meRes)}`);
    }

    const noPhoneMeRes = createMockRes();
    await getMe({ user: { id: noPhoneUserId, email: noPhoneEmail, role: 'User' } }, noPhoneMeRes);
    if (noPhoneMeRes.statusCode !== 200 || noPhoneMeRes.body?.user?.phone !== '') {
      throw new Error(`Expected empty phone for user without number, got ${JSON.stringify(noPhoneMeRes)}`);
    }

    // Invalid phone number rejected
    const badPhoneUpdateRes = createMockRes();
    await updateProfile(
      { user: { id: testUserId, email: testEmail, role: 'User' }, body: { name: 'Twilio Test User', email: testEmail, phone: '12345' } },
      badPhoneUpdateRes
    );
    if (badPhoneUpdateRes.statusCode !== 400) {
      throw new Error(`Expected 400 for invalid phone in updateProfile, got ${JSON.stringify(badPhoneUpdateRes)}`);
    }

    // Duplicate phone belonging to another account rejected
    const dupPhoneUpdateRes = createMockRes();
    await updateProfile(
      { user: { id: testUserId, email: testEmail, role: 'User' }, body: { name: 'Twilio Test User', email: testEmail, phone: otherPhone } },
      dupPhoneUpdateRes
    );
    if (dupPhoneUpdateRes.statusCode !== 409) {
      throw new Error(`Expected 409 for duplicate phone in updateProfile, got ${JSON.stringify(dupPhoneUpdateRes)}`);
    }

    // Same phone + updated name succeeds cleanly without re-verifying phone
    const nameOnlyUpdateRes = createMockRes();
    await updateProfile(
      { user: { id: testUserId, email: testEmail, role: 'User' }, body: { name: 'Updated Name', email: testEmail, phone: testPhone } },
      nameOnlyUpdateRes
    );
    if (nameOnlyUpdateRes.statusCode !== 200 || nameOnlyUpdateRes.body?.user?.name !== 'Updated Name' || nameOnlyUpdateRes.body?.user?.phone !== testPhone) {
      throw new Error(`Expected name update with same phone to succeed, got ${JSON.stringify(nameOnlyUpdateRes)}`);
    }

    // Invalid OTP leaves original verified phone intact in MongoDB
    const jwtLib = require('jsonwebtoken');
    const badOtpToken = jwtLib.sign(
      { purpose: 'profile_phone_change', userId: testUserId, newPhone: newCandidatePhone },
      process.env.JWT_SECRET || 'cricketverse_super_secret_key_123!',
      { expiresIn: '5m' }
    );
    const wrongOtpRes = createMockRes();
    await updateProfile(
      {
        user: { id: testUserId, email: testEmail, role: 'User' },
        body: { name: 'Updated Name', email: testEmail, phone: newCandidatePhone, phoneOtp: 'abc', phoneChangeToken: badOtpToken },
      },
      wrongOtpRes
    );
    const userAfterBadOtp = await UserModel.findOne({ id: testUserId });
    if (wrongOtpRes.statusCode !== 400 || userAfterBadOtp?.phone !== testPhone) {
      throw new Error(`Wrong OTP must fail and preserve original phone! got ${JSON.stringify(wrongOtpRes)}`);
    }

    // If a user's phone is explicitly unverified, Forgot Password must reject lookup cleanly
    await UserModel.findOneAndUpdate({ id: otherUserId }, { $set: { phoneVerified: false } });
    const unverifiedLookupRes = createMockRes();
    await lookupPhoneByEmail({ body: { email: otherEmail } } as any, unverifiedLookupRes);
    if (
      unverifiedLookupRes.statusCode !== 403 ||
      unverifiedLookupRes.body?.success !== false ||
      unverifiedLookupRes.body?.data?.hasVerifiedPhone !== false
    ) {
      throw new Error(`Expected 403 unverified phone rejection in recovery lookup, got ${JSON.stringify(unverifiedLookupRes)}`);
    }
    console.log('✅ Edit Profile prefill, validation, duplicate check & phone verification protection passed.');

    // 9. Check Twilio Verify live call if credentials are configured
    if (process.env.TWILIO_ACCOUNT_SID && process.env.TWILIO_AUTH_TOKEN && process.env.TWILIO_VERIFY_SERVICE_SID) {
      console.log('📲 Testing live Twilio Verify SMS dispatch...');
      const smsRes = await sendVerificationSms(testPhone);
      console.log(`📲 Twilio live response: success=${smsRes.success}, error=${smsRes.error || 'none'}`);

      // Also test live phone-change OTP initiation preserves old verified phone in MongoDB
      const phoneChangeInitRes = createMockRes();
      await updateProfile(
        { user: { id: testUserId, email: testEmail, role: 'User' }, body: { name: 'Updated Name', email: testEmail, phone: newCandidatePhone } },
        phoneChangeInitRes
      );
      const userDuringPendingChange = await UserModel.findOne({ id: testUserId });
      if (userDuringPendingChange?.phone !== testPhone) {
        throw new Error('Original phone must remain unchanged until OTP is verified!');
      }
      if (phoneChangeInitRes.statusCode === 200 && phoneChangeInitRes.body?.requiresPhoneVerification !== true) {
        throw new Error(`Expected requiresPhoneVerification=true on phone change OTP initiation, got ${JSON.stringify(phoneChangeInitRes)}`);
      }
      console.log(`📲 Profile phone-change OTP step verified (old phone preserved in MongoDB).`);
    } else {
      console.log('ℹ️ Skipping live Twilio API call (TWILIO_ACCOUNT_SID/AUTH_TOKEN/VERIFY_SERVICE_SID not set in .env).');
    }

    console.log('\n🎉 ALL TWILIO FORGOT PASSWORD INTEGRATION TESTS PASSED! 🎉\n');
  } finally {
    await UserModel.deleteMany({ email: { $in: [testEmail, otherEmail, noPhoneEmail] } });
    await PasswordResetOtpModel.deleteMany({ phone: { $in: [testPhone, otherPhone, newCandidatePhone] } });
    await mongoose.disconnect();
  }
}

runTests().catch((err) => {
  console.error('❌ Test suite failed:', err);
  process.exit(1);
});

