import mongoose, { Schema, Document } from 'mongoose';

export interface IEmailConfig extends Document {
  id: string;
  senderEmail: string;
  senderName: string;
  appPassword?: string;
  host: string;
  port: number;
  secure: boolean;
  isConfigured: boolean;
  updatedBy: string;
  createdAt: Date;
  updatedAt: Date;
}

const EmailConfigSchema = new Schema<IEmailConfig>(
  {
    id: { type: String, required: true, unique: true, default: 'global_email_config' },
    senderEmail: { type: String, required: true, trim: true },
    senderName: { type: String, default: 'CricketVerse', trim: true },
    appPassword: { type: String, default: '' },
    host: { type: String, default: 'smtp.gmail.com', trim: true },
    port: { type: Number, default: 465 },
    secure: { type: Boolean, default: true },
    isConfigured: { type: Boolean, default: false },
    updatedBy: { type: String, default: 'Admin' },
  },
  {
    timestamps: true,
    toJSON: {
      virtuals: true,
      transform: (doc, ret: any) => {
        delete ret._id;
        delete ret.__v;
        // NEVER expose the app password
        delete ret.appPassword;
        return ret;
      },
    },
  }
);

export const EmailConfigModel =
  mongoose.models.EmailConfig || mongoose.model<IEmailConfig>('EmailConfig', EmailConfigSchema);
