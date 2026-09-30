import mongoose, { Schema, Document } from 'mongoose';

export interface IPlayer {
  id: string;
  name: string;
  role: string;
  nationality: string;
  isCaptain: boolean;
  isViceCaptain: boolean;
  runsScored: number;
  ballsFaced: number;
  wicketsTaken: number;
  runsConceded: number;
  oversBowled: number;
  matchesPlayed: number;
}

export const PlayerSchema = new Schema<IPlayer>(
  {
    id: { type: String, required: true },
    name: { type: String, required: true },
    role: { type: String, default: 'Batter' },
    nationality: { type: String, default: 'IND' },
    isCaptain: { type: Boolean, default: false },
    isViceCaptain: { type: Boolean, default: false },
    runsScored: { type: Number, default: 0 },
    ballsFaced: { type: Number, default: 0 },
    wicketsTaken: { type: Number, default: 0 },
    runsConceded: { type: Number, default: 0 },
    oversBowled: { type: Number, default: 0.0 },
    matchesPlayed: { type: Number, default: 0 },
  },
  { _id: false }
);

export interface ITeam extends Document {
  id: string;
  name: string;
  shortName: string;
  logoColorHex: string;
  players: IPlayer[];
  createdAt: Date;
  updatedAt: Date;
}

const TeamSchema = new Schema<ITeam>(
  {
    id: { type: String, required: true, unique: true, index: true },
    name: { type: String, required: true, trim: true },
    shortName: { type: String, required: true, trim: true },
    logoColorHex: { type: String, default: '0xFF028A6B' },
    players: { type: [PlayerSchema], default: [] },
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

export const TeamModel = mongoose.models.Team || mongoose.model<ITeam>('Team', TeamSchema);
