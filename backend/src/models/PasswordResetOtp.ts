import mongoose, { Schema, Document } from 'mongoose';

export interface IPasswordResetOtp extends Document {
  email: string;
  otpHash: string;
  attempts: number;
  verified: boolean;
  resetToken?: string | null;
  resetTokenExpiresAt?: Date | null;
  expiresAt: Date;
  lastRequestedAt: Date;
  createdAt: Date;
}

const PasswordResetOtpSchema = new Schema<IPasswordResetOtp>(
  {
    email: { type: String, required: true, lowercase: true, trim: true, index: true },
    otpHash: { type: String, required: true },
    attempts: { type: Number, default: 0 },
    verified: { type: Boolean, default: false },
    resetToken: { type: String, default: null, index: true },
    resetTokenExpiresAt: { type: Date, default: null },
    expiresAt: { type: Date, required: true },
    lastRequestedAt: { type: Date },
    createdAt: { type: Date, default: Date.now, expires: 900 }, // Cleaned up after 15 minutes
  },
  {
    timestamps: false,
  }
);

export const PasswordResetOtpModel =
  mongoose.models.PasswordResetOtp ||
  mongoose.model<IPasswordResetOtp>('PasswordResetOtp', PasswordResetOtpSchema);
