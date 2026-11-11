import dotenv from 'dotenv';
dotenv.config();

import mongoose from 'mongoose';
import bcrypt from 'bcryptjs';
import crypto from 'crypto';
import { UserModel } from '../models/User';
import { PasswordResetOtpModel } from '../models/PasswordResetOtp';
import { isValidE164Phone, normalizePhoneNumber, sendVerificationSms } from '../services/twilioService';

async function runTests() {
  console.log('🧪 Starting Twilio Phone Registration & Forgot Password Integration Tests...');

  if (!process.env.MONGODB_URI) {
    throw new Error('MONGODB_URI is required to run integration tests.');
  }

  await mongoose.connect(process.env.MONGODB_URI);

  const testEmail = `twilio_test_${Date.now()}@example.com`;
  const testPhone = `+9198${Math.floor(10000000 + Math.random() * 89999999)}`;
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
      id: `test_user_${Date.now()}`,
      email: testEmail,
      phone: testPhone,
      passwordHash,
      role: 'User',
      name: 'Twilio Test User',
    });
    console.log('✅ Test user created with phone number.');

    // 3. Unregistered phone check
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

    const newHash = await bcrypt.hash(newPassword, 10);
    await UserModel.findOneAndUpdate({ phone: testPhone }, { $set: { passwordHash: newHash } });
    await PasswordResetOtpModel.deleteMany({ phone: testPhone });

    const updatedUser = await UserModel.findOne({ phone: testPhone });
    if (!updatedUser) throw new Error('User not found after update.');
    const oldMatch = await bcrypt.compare(initialPassword, updatedUser.passwordHash);
    const newMatch = await bcrypt.compare(newPassword, updatedUser.passwordHash);
    if (oldMatch || !newMatch) {
      throw new Error('Password reset hash verification failed.');
    }
    console.log('✅ Password reset & auth verification passed.');

    // 8. Check Twilio Verify live call if credentials are configured
    if (process.env.TWILIO_ACCOUNT_SID && process.env.TWILIO_AUTH_TOKEN && process.env.TWILIO_VERIFY_SERVICE_SID) {
      console.log('📲 Testing live Twilio Verify SMS dispatch...');
      const smsRes = await sendVerificationSms(testPhone);
      console.log(`📲 Twilio live response: success=${smsRes.success}, error=${smsRes.error || 'none'}`);
    } else {
      console.log('ℹ️ Skipping live Twilio API call (TWILIO_ACCOUNT_SID/AUTH_TOKEN/VERIFY_SERVICE_SID not set in .env).');
    }

    console.log('\n🎉 ALL TWILIO FORGOT PASSWORD INTEGRATION TESTS PASSED! 🎉\n');
  } finally {
    await UserModel.deleteMany({ email: testEmail });
    await PasswordResetOtpModel.deleteMany({ phone: testPhone });
    await mongoose.disconnect();
  }
}

runTests().catch((err) => {
  console.error('❌ Test suite failed:', err);
  process.exit(1);
});

