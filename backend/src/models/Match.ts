import mongoose, { Schema, Document } from 'mongoose';
import { IPlayer, PlayerSchema } from './Team';

export interface IBallRecord {
  run: number;
  extraRun: number;
  extraType: string;
  isWicket: boolean;
  wicketType: string;
  batsmanName: string;
  bowlerName: string;
  commentary: string;
  audioUrl?: string;
  timestamp: string;
  strikerId?: string;
  nonStrikerId?: string;
  bowlerId?: string;
  innings?: number;
  battingTeamId?: string;
  over?: number;
}

export const BallRecordSchema = new Schema<IBallRecord>(
  {
    run: { type: Number, default: 0 },
    extraRun: { type: Number, default: 0 },
    extraType: { type: String, default: 'None' },
    isWicket: { type: Boolean, default: false },
    wicketType: { type: String, default: 'None' },
    batsmanName: { type: String, default: '' },
    bowlerName: { type: String, default: '' },
    commentary: { type: String, default: '' },
    audioUrl: { type: String },
    timestamp: { type: String, default: () => new Date().toISOString() },
    strikerId: { type: String },
    nonStrikerId: { type: String },
    bowlerId: { type: String },
    innings: { type: Number, default: 1 },
    battingTeamId: { type: String },
    over: { type: Number, default: 0.0 },
  },
  { _id: false }
);

export interface IMatch extends Document {
  id: string;
  tournamentId?: string;
  teamAId: string;
  teamBId: string;
  teamA: any;
  teamB: any;
  matchType: string;
  venue: string;
  date: string;
  time: string;
  status: 'Upcoming' | 'Live' | 'Completed';
  tossWinner: string;
  tossDecision: string;
  battingTeamId: string;
  playingXI_A: IPlayer[];
  playingXI_B: IPlayer[];
  runsA: number;
  wicketsA: number;
  oversA: number;
  runsB: number;
  wicketsB: number;
  oversB: number;
  target: number;
  scorerUsername: string;
  scorerPassword: string;
  currentStrikerId: string;
  currentNonStrikerId: string;
  currentBowlerId: string;
  isFirstInnings: boolean;
  balls: IBallRecord[];
  winnerTeamId?: string;
  winnerName?: string;
  resultText?: string;
  createdAt: Date;
  updatedAt: Date;
}

const MatchSchema = new Schema<IMatch>(
  {
    id: { type: String, required: true, unique: true, index: true },
    tournamentId: { type: String, index: true },
    teamAId: { type: String, required: true, index: true },
    teamBId: { type: String, required: true, index: true },
    teamA: { type: Schema.Types.Mixed, required: true },
    teamB: { type: Schema.Types.Mixed, required: true },
    matchType: { type: String, default: 'T20' },
    venue: { type: String, required: true },
    date: { type: String, required: true },
    time: { type: String, required: true },
    status: { type: String, enum: ['Upcoming', 'Live', 'Completed'], default: 'Upcoming', index: true },
    tossWinner: { type: String, default: '' },
    tossDecision: { type: String, default: '' },
    battingTeamId: { type: String, default: '' },
    playingXI_A: { type: [PlayerSchema], default: [] },
    playingXI_B: { type: [PlayerSchema], default: [] },
    runsA: { type: Number, default: 0 },
    wicketsA: { type: Number, default: 0 },
    oversA: { type: Number, default: 0.0 },
    runsB: { type: Number, default: 0 },
    wicketsB: { type: Number, default: 0 },
    oversB: { type: Number, default: 0.0 },
    target: { type: Number, default: 0 },
    scorerUsername: { type: String, required: true, index: true },
    scorerPassword: { type: String, required: true },
    currentStrikerId: { type: String, default: '' },
    currentNonStrikerId: { type: String, default: '' },
    currentBowlerId: { type: String, default: '' },
    isFirstInnings: { type: Boolean, default: true },
    balls: { type: [BallRecordSchema], default: [] },
    winnerTeamId: { type: String, default: '' },
    winnerName: { type: String, default: '' },
    resultText: { type: String, default: '' },
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

export const MatchModel = mongoose.models.Match || mongoose.model<IMatch>('Match', MatchSchema);
