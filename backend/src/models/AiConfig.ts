import mongoose, { Schema, Document } from 'mongoose';

export interface IAiConfig extends Document {
  id: string;
  apiKey: string;
  voiceId: string;
  voiceName: string;
  modelId: string;
  stability: number;
  similarityBoost: number;
  style: number;
  useSpeakerBoost: boolean;
  autoPlayVoice: boolean;
  commentaryStyle: string;
  commentaryTrigger: string;
  isConfigured: boolean;
  updatedBy: string;
  createdAt: Date;
  updatedAt: Date;
}

const AiConfigSchema = new Schema<IAiConfig>(
  {
    id: { type: String, required: true, unique: true, default: 'global_ai_config' },
    apiKey: { type: String, default: '' },
    voiceId: { type: String, default: 'JBFqnCBsd6RMkjVDRZzb' },
    voiceName: { type: String, default: 'George (Cricket Classic)' },
    modelId: { type: String, default: 'eleven_turbo_v2_5' },
    stability: { type: Number, default: 0.5 },
    similarityBoost: { type: Number, default: 0.8 },
    style: { type: Number, default: 0.35 },
    useSpeakerBoost: { type: Boolean, default: true },
    autoPlayVoice: { type: Boolean, default: true },
    commentaryStyle: { type: String, default: 'Hype / Energetic' },
    commentaryTrigger: { type: String, default: 'Every Ball' },
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
        return ret;
      },
    },
  }
);

export const AiConfigModel =
  mongoose.models.AiConfig || mongoose.model<IAiConfig>('AiConfig', AiConfigSchema);
