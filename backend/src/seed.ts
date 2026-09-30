import mongoose from 'mongoose';
import dotenv from 'dotenv';
import bcrypt from 'bcryptjs';
import { UserModel } from './models/User';
import { TeamModel } from './models/Team';
import { TournamentModel } from './models/Tournament';
import { MatchModel } from './models/Match';
import { NotificationModel } from './models/Notification';

dotenv.config();

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb+srv://kansagarakrish2006_db_user:QwPR8HgyNiy41HDi@cluster0.cxx9cqz.mongodb.net/cricketverse?retryWrites=true&w=majority';

async function seed() {
  try {
    console.log('Connecting to MongoDB Atlas...');
    await mongoose.connect(MONGODB_URI);
    console.log('Connected.');

    // 1. Seed Users
    const adminHash = await bcrypt.hash('admin123', 10);
    const userHash = await bcrypt.hash('user123', 10);

    await UserModel.findOneAndUpdate(
      { email: 'admin@gmail.com' },
      {
        id: 'admin_user',
        email: 'admin@gmail.com',
        passwordHash: adminHash,
        role: 'Admin',
        name: 'Rajesh Kumar',
      },
      { upsert: true, returnDocument: 'after' }
    );

    await UserModel.findOneAndUpdate(
      { email: 'user@gmail.com' },
      {
        id: 'user_gmail',
        email: 'user@gmail.com',
        passwordHash: userHash,
        role: 'User',
        name: 'Cricket Fan',
      },
      { upsert: true, returnDocument: 'after' }
    );
    console.log('✅ Users seeded: admin@gmail.com / admin123, user@gmail.com / user123');

    // 2. Seed Teams & Players
    const team1Id = 'team_mumbai_indians';
    const team2Id = 'team_chennai_kings';

    await TeamModel.findOneAndUpdate(
      { id: team1Id },
      {
        id: team1Id,
        name: 'Mumbai Mavericks',
        shortName: 'MM',
        logoColorHex: '0xFF0D47A1',
        players: [
          { id: `${team1Id}_p1`, name: 'Rohit Sharma', role: 'Batter', nationality: 'IND', isCaptain: true, runsScored: 450, ballsFaced: 310, matchesPlayed: 14 },
          { id: `${team1Id}_p2`, name: 'Ishan Kishan', role: 'Wicketkeeper', nationality: 'IND', runsScored: 380, ballsFaced: 270, matchesPlayed: 14 },
          { id: `${team1Id}_p3`, name: 'Suryakumar Yadav', role: 'Batter', nationality: 'IND', runsScored: 520, ballsFaced: 290, matchesPlayed: 14 },
          { id: `${team1Id}_p4`, name: 'Hardik Pandya', role: 'All-rounder', nationality: 'IND', isViceCaptain: true, runsScored: 280, ballsFaced: 180, wicketsTaken: 12, oversBowled: 34.0, matchesPlayed: 14 },
          { id: `${team1Id}_p5`, name: 'Tim David', role: 'Batter', nationality: 'AUS', runsScored: 210, ballsFaced: 120, matchesPlayed: 12 },
          { id: `${team1Id}_p6`, name: 'Jasprit Bumrah', role: 'Bowler', nationality: 'IND', wicketsTaken: 22, runsConceded: 320, oversBowled: 54.0, matchesPlayed: 14 },
          { id: `${team1Id}_p7`, name: 'Piyush Chawla', role: 'Bowler', nationality: 'IND', wicketsTaken: 16, runsConceded: 380, oversBowled: 48.0, matchesPlayed: 14 },
        ],
      },
      { upsert: true, returnDocument: 'after' }
    );

    await TeamModel.findOneAndUpdate(
      { id: team2Id },
      {
        id: team2Id,
        name: 'Chennai Champions',
        shortName: 'CC',
        logoColorHex: '0xFFFFC107',
        players: [
          { id: `${team2Id}_p1`, name: 'Ruturaj Gaikwad', role: 'Batter', nationality: 'IND', isCaptain: true, runsScored: 490, ballsFaced: 350, matchesPlayed: 14 },
          { id: `${team2Id}_p2`, name: 'Devon Conway', role: 'Batter', nationality: 'NZ', runsScored: 410, ballsFaced: 310, matchesPlayed: 12 },
          { id: `${team2Id}_p3`, name: 'Shivam Dube', role: 'All-rounder', nationality: 'IND', runsScored: 360, ballsFaced: 210, matchesPlayed: 14 },
          { id: `${team2Id}_p4`, name: 'MS Dhoni', role: 'Wicketkeeper', nationality: 'IND', runsScored: 190, ballsFaced: 95, matchesPlayed: 14 },
          { id: `${team2Id}_p5`, name: 'Ravindra Jadeja', role: 'All-rounder', nationality: 'IND', isViceCaptain: true, runsScored: 230, ballsFaced: 160, wicketsTaken: 15, oversBowled: 44.0, matchesPlayed: 14 },
          { id: `${team2Id}_p6`, name: 'Matheesha Pathirana', role: 'Bowler', nationality: 'SL', wicketsTaken: 19, runsConceded: 290, oversBowled: 42.0, matchesPlayed: 12 },
          { id: `${team2Id}_p7`, name: 'Deepak Chahar', role: 'Bowler', nationality: 'IND', wicketsTaken: 14, runsConceded: 340, oversBowled: 46.0, matchesPlayed: 14 },
        ],
      },
      { upsert: true, returnDocument: 'after' }
    );
    console.log('✅ Teams & Players seeded: Mumbai Mavericks & Chennai Champions');

    // 3. Seed Tournament
    const tournamentId = 'tournament_ipl_2026';
    await TournamentModel.findOneAndUpdate(
      { id: tournamentId },
      {
        id: tournamentId,
        name: 'Indian Premier Trophy 2026',
        format: 'T20',
        status: 'Live',
        teamsCount: 2,
        matchesCount: 1,
        startDate: '01-04-2026',
        endDate: '30-05-2026',
        participatingTeamIds: [team1Id, team2Id],
      },
      { upsert: true, returnDocument: 'after' }
    );
    console.log('✅ Tournament seeded: Indian Premier Trophy 2026');

    // 4. Seed Live Match
    const matchId = 'match_live_showcase';
    const team1 = await TeamModel.findOne({ id: team1Id }).lean();
    const team2 = await TeamModel.findOne({ id: team2Id }).lean();

    await MatchModel.findOneAndUpdate(
      { id: matchId },
      {
        id: matchId,
        tournamentId,
        teamAId: team1Id,
        teamBId: team2Id,
        teamA: team1,
        teamB: team2,
        matchType: 'T20',
        venue: 'Wankhede Stadium, Mumbai',
        date: '30-09-2026',
        time: '19:30',
        status: 'Live',
        tossWinner: team1Id,
        tossDecision: 'Bat',
        battingTeamId: team1Id,
        playingXI_A: team1?.players || [],
        playingXI_B: team2?.players || [],
        runsA: 84,
        wicketsA: 2,
        oversA: 9.4,
        runsB: 0,
        wicketsB: 0,
        oversB: 0.0,
        target: 0,
        scorerUsername: 'scorer_wankhede',
        scorerPassword: 'scorer123',
        currentStrikerId: `${team1Id}_p3`,
        currentNonStrikerId: `${team1Id}_p4`,
        currentBowlerId: `${team2Id}_p5`,
        isFirstInnings: true,
        balls: [
          {
            run: 4,
            extraRun: 0,
            extraType: 'None',
            isWicket: false,
            wicketType: 'None',
            batsmanName: 'Rohit Sharma',
            bowlerName: 'Deepak Chahar',
            commentary: 'FOUR! GLORIOUS COVER DRIVE! Rohit Sharma leans into the half-volley and pierces the boundary gap!',
            timestamp: new Date(Date.now() - 3600000).toISOString(),
          },
          {
            run: 6,
            extraRun: 0,
            extraType: 'None',
            isWicket: false,
            wicketType: 'None',
            batsmanName: 'Suryakumar Yadav',
            bowlerName: 'Ravindra Jadeja',
            commentary: 'SIX! MASSIVE HIT! Suryakumar Yadav scoops it over fine leg 90 meters into the stands!',
            timestamp: new Date(Date.now() - 1800000).toISOString(),
          },
        ],
      },
      { upsert: true, returnDocument: 'after' }
    );
    console.log('✅ Live Match seeded: Mumbai Mavericks vs Chennai Champions (Scorer: scorer_wankhede / scorer123)');

    // 5. Seed Notification
    await NotificationModel.create({
      id: `notif_${Date.now()}`,
      userId: 'global',
      title: 'Welcome to CricketVerse AI! 🏏',
      message: 'MongoDB Atlas is now fully connected with real-time scoring and AI commentary.',
      category: 'System',
      readBy: [],
    });
    console.log('✅ Notification seeded.');

    await mongoose.disconnect();
    console.log('✨ Database seeding finished successfully.');
    process.exit(0);
  } catch (err) {
    console.error('Seed error:', err);
    process.exit(1);
  }
}

seed();
