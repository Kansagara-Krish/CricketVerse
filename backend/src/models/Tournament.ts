import mongoose, { Schema, Document } from 'mongoose';

export interface ITournament extends Document {
  id: string;
  name: string;
  format: string;
  status: 'Upcoming' | 'Live' | 'Completed';
  teamsCount: number;
  matchesCount: number;
  startDate: string;
  endDate: string;
  participatingTeamIds: string[];
  createdAt: Date;
  updatedAt: Date;
}

const TournamentSchema = new Schema<ITournament>(
  {
    id: { type: String, required: true, unique: true, index: true },
    name: { type: String, required: true, trim: true },
    format: { type: String, default: 'T20' },
    status: { type: String, enum: ['Upcoming', 'Live', 'Completed'], default: 'Upcoming', index: true },
    teamsCount: { type: Number, default: 0 },
    matchesCount: { type: Number, default: 0 },
    startDate: { type: String, default: '' },
    endDate: { type: String, default: '' },
    participatingTeamIds: { type: [String], default: [] },
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

export const TournamentModel = mongoose.models.Tournament || mongoose.model<ITournament>('Tournament', TournamentSchema);
