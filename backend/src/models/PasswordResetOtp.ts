import mongoose, { Schema, Document } from 'mongoose';

export interface IPasswordResetOtp extends Document {
  email: string;
  otp: string;
  createdAt: Date;
  verified: boolean;
}

const PasswordResetOtpSchema = new Schema<IPasswordResetOtp>(
  {
    email: { type: String, required: true, lowercase: true, trim: true, index: true },
    otp: { type: String, required: true },
    verified: { type: Boolean, default: false },
    createdAt: { type: Date, default: Date.now, expires: 600 }, // Expires automatically in 10 minutes (600s)
  },
  {
    timestamps: false,
  }
);

export const PasswordResetOtpModel =
  mongoose.models.PasswordResetOtp ||
  mongoose.model<IPasswordResetOtp>('PasswordResetOtp', PasswordResetOtpSchema);
