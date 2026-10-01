import mongoose, { Schema, Document } from 'mongoose';

export interface IManager extends Document {
  id: string;
  name: string;
  username: string;
  password: string;
  phone?: string;
  createdAt: Date;
  updatedAt: Date;
}

const ManagerSchema = new Schema<IManager>(
  {
    id: { type: String, required: true, unique: true, index: true },
    name: { type: String, required: true, trim: true },
    username: { type: String, required: true, unique: true, trim: true, lowercase: true, index: true },
    password: { type: String, required: true },
    phone: { type: String, default: '', trim: true },
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

export const ManagerModel = mongoose.models.Manager || mongoose.model<IManager>('Manager', ManagerSchema);
