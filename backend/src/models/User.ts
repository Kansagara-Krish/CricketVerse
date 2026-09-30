import mongoose, { Schema, Document } from 'mongoose';

export interface IUser extends Document {
  id: string;
  email: string;
  passwordHash: string;
  role: 'Admin' | 'Scorer' | 'User' | 'Manager';
  name: string;
  favoriteTeams: string[];
  notificationSettings: {
    liveMatches: boolean;
    newTournaments: boolean;
    commentary: boolean;
  };
  createdAt: Date;
  updatedAt: Date;
}

const UserSchema = new Schema<IUser>(
  {
    id: { type: String, required: true, unique: true, index: true },
    email: { type: String, required: true, unique: true, lowercase: true, trim: true, index: true },
    passwordHash: { type: String, required: true },
    role: { type: String, enum: ['Admin', 'Scorer', 'User', 'Manager'], default: 'User', index: true },
    name: { type: String, default: '', trim: true },
    favoriteTeams: { type: [String], default: [] },
    notificationSettings: {
      liveMatches: { type: Boolean, default: true },
      newTournaments: { type: Boolean, default: true },
      commentary: { type: Boolean, default: true },
    },
  },
  {
    timestamps: true,
    toJSON: {
      virtuals: true,
      transform: (doc, ret: any) => {
        delete ret._id;
        delete ret.__v;
        delete ret.passwordHash;
        return ret;
      },
    },
  }
);

export const UserModel = mongoose.models.User || mongoose.model<IUser>('User', UserSchema);
