import { PrismaClient } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';
import { Pool } from 'pg';
import dotenv from 'dotenv';
import bcrypt from 'bcryptjs';

dotenv.config();

const connectionString = process.env.DATABASE_URL || 'postgresql://postgres:postgres@localhost:5432/cricketverse';
const pool = new Pool({ connectionString });
const adapter = new PrismaPg(pool);

export const prisma = new PrismaClient({ adapter });

export async function initDatabase() {
  try {
    await prisma.$connect();
    console.log('Connected to PostgreSQL database via Prisma successfully.');

    // Seed initial users if empty
    const userCount = await prisma.user.count();
    if (userCount === 0) {
      console.log('Seeding initial users...');
      const adminPassHash = await bcrypt.hash('admin123', 10);
      const userPassHash = await bcrypt.hash('user123', 10);
      const alexPassHash = await bcrypt.hash('alex123', 10);

      await prisma.user.createMany({
        data: [
          { id: 'admin_user', email: 'admin@cricketverse.ai', passwordHash: adminPassHash, role: 'Admin' },
          { id: 'user_gmail', email: 'user@gmail.com', passwordHash: userPassHash, role: 'User' },
          { id: 'user_alex', email: 'alex@gmail.com', passwordHash: alexPassHash, role: 'User' },
        ],
      });
      console.log('Users seeded.');
    }

    // Seed default teams and players if empty
    const teamCount = await prisma.team.count();
    if (teamCount === 0) {
      console.log('Seeding default teams and players...');

      const firstNames = [
        'Aarav', 'Vihaan', 'Arjun', 'Kabir', 'Ishaan', 'Rohan', 'Aditya', 'Kunal',
        'Reyansh', 'Vivaan', 'Advik', 'Sai', 'Atharva', 'Shaurya', 'Rudra', 'Aaryan',
        'Veer', 'Aayaan', 'Kiaan', 'Krishna', 'Dev', 'Aryan', 'Madhav', 'Ryan',
        'Dhruv', 'Kian', 'Yuvan'
      ];
      const lastNames = ['Patel', 'Shah', 'Mehta', 'Sharma', 'Joshi', 'Gani', 'Amin', 'Chaudhari', 'Vaghela', 'Trivedi', 'Dave'];

      const defaultTeams = [
        { id: 'uvpce_a', name: 'UVPCE - A', shortName: 'UVPCE - A', logoColorHex: '0xFF028A6B', startIndex: 0 },
        { id: 'uvpce_b', name: 'UVPCE - B', shortName: 'UVPCE - B', logoColorHex: '0xFF10B981', startIndex: 5 },
        { id: 'uvpce_c', name: 'UVPCE - C', shortName: 'UVPCE - C', logoColorHex: '0xFFD97706', startIndex: 10 },
        { id: 'uvpce_titans', name: 'UVPCE - Titans', shortName: 'UVPCE - Titans', logoColorHex: '0xFFF59E0B', startIndex: 15 },
        { id: 'uvpce_warriors', name: 'UVPCE - Warriors', shortName: 'UVPCE - Warriors', logoColorHex: '0xFFEF4444', startIndex: 20 },
        { id: 'uvpce_challengers', name: 'UVPCE - Challengers', shortName: 'UVPCE - Challengers', logoColorHex: '0xFFEA580C', startIndex: 25 },
        { id: 'uvpce_strikers', name: 'UVPCE - Strikers', shortName: 'UVPCE - Strikers', logoColorHex: '0xFF0B6623', startIndex: 3 },
        { id: 'uvpce_legends', name: 'UVPCE - Legends', shortName: 'UVPCE - Legends', logoColorHex: '0xFF14B8A6', startIndex: 8 },
      ];

      for (const t of defaultTeams) {
        await prisma.team.create({
          data: {
            id: t.id,
            name: t.name,
            shortName: t.shortName,
            logoColorHex: t.logoColorHex,
          },
        });

        const roles = ['Batter', 'Batter', 'Batter', 'Batter', 'All-rounder', 'All-rounder', 'All-rounder', 'Bowler', 'Bowler', 'Bowler', 'Bowler'];
        for (let i = 0; i < 11; i++) {
          const fName = firstNames[(t.startIndex + i) % firstNames.length];
          const lName = lastNames[(t.startIndex * 3 + i) % lastNames.length];
          const fullName = `${fName} ${lName}`;
          const pId = `${t.id.toLowerCase()}_${fName.toLowerCase()}_${i}`;

          const runs = (200 + (t.startIndex * 35 + i * 55) % 1800);
          const wickets = (i >= 7) ? (10 + (t.startIndex * 4 + i * 5) % 50) : (0 + (t.startIndex + i) % 4);
          const matches = 15 + Math.floor(runs / 120);

          await prisma.player.create({
            data: {
              id: pId,
              name: fullName,
              role: roles[i],
              nationality: 'IND',
              runsScored: runs,
              ballsFaced: Math.round(runs * 1.3),
              wicketsTaken: wickets,
              matchesPlayed: matches,
              teams: {
                create: {
                  teamId: t.id,
                },
              },
            },
          });
        }
      }
      console.log('Teams and players seeded.');
    }

    // Seed default matches if empty
    const matchCount = await prisma.match.count();
    if (matchCount === 0) {
      console.log('Seeding default matches...');

      // Live Match: Titans vs Warriors
      await prisma.match.create({
        data: {
          id: 'live_world_cup_final',
          teamAId: 'uvpce_titans',
          teamBId: 'uvpce_warriors',
          matchType: 'T20',
          venue: 'Narendra Modi Stadium',
          date: '17-07-2026',
          time: '19:30',
          status: 'Live',
          tossWinner: 'UVPCE - Titans',
          tossDecision: 'Bat',
          battingTeamId: 'uvpce_titans',
          runsA: 145,
          wicketsA: 4,
          oversA: 15.4,
          runsB: 0,
          wicketsB: 0,
          oversB: 0.0,
          target: 185,
          scorerUsername: 'scorer1',
          scorerPassword: '123',
          currentStrikerId: 'uvpce_titans_aarav_0',
          currentNonStrikerId: 'uvpce_titans_vihaan_1',
          currentBowlerId: 'uvpce_warriors_rudra_10',
          isFirstInnings: true,
        },
      });

      const titansPlayers = await prisma.teamPlayer.findMany({ where: { teamId: 'uvpce_titans' } });
      for (const p of titansPlayers) {
        await prisma.matchPlayingXI.create({
          data: { matchId: 'live_world_cup_final', teamId: 'uvpce_titans', playerId: p.playerId },
        });
      }

      const warriorsPlayers = await prisma.teamPlayer.findMany({ where: { teamId: 'uvpce_warriors' } });
      for (const p of warriorsPlayers) {
        await prisma.matchPlayingXI.create({
          data: { matchId: 'live_world_cup_final', teamId: 'uvpce_warriors', playerId: p.playerId },
        });
      }

      // Completed Match: UVPCE A vs UVPCE B
      await prisma.match.create({
        data: {
          id: 'completed_bilateral_1',
          teamAId: 'uvpce_a',
          teamBId: 'uvpce_b',
          matchType: 'T20',
          venue: 'Wankhede Stadium',
          date: '15-07-2026',
          time: '14:30',
          status: 'Completed',
          tossWinner: 'UVPCE - B',
          tossDecision: 'Bowl',
          battingTeamId: 'uvpce_a',
          runsA: 168,
          wicketsA: 6,
          oversA: 20.0,
          runsB: 169,
          wicketsB: 5,
          oversB: 19.3,
          target: 169,
          scorerUsername: 'scorer2',
          scorerPassword: '456',
          isFirstInnings: false,
        },
      });

      const aPlayers = await prisma.teamPlayer.findMany({ where: { teamId: 'uvpce_a' } });
      for (const p of aPlayers) {
        await prisma.matchPlayingXI.create({
          data: { matchId: 'completed_bilateral_1', teamId: 'uvpce_a', playerId: p.playerId },
        });
      }

      const bPlayers = await prisma.teamPlayer.findMany({ where: { teamId: 'uvpce_b' } });
      for (const p of bPlayers) {
        await prisma.matchPlayingXI.create({
          data: { matchId: 'completed_bilateral_1', teamId: 'uvpce_b', playerId: p.playerId },
        });
      }

      console.log('Matches seeded.');
    }
  } catch (err) {
    console.error('Error initializing database with Prisma:', err);
  }
}
