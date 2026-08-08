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

    // Clean up previous runs' default records
    console.log('Cleaning up old default records...');
    await prisma.ballRecord.deleteMany({
      where: {
        matchId: {
          in: ['live_world_cup_final', 'completed_bilateral_1']
        }
      }
    });

    await prisma.matchPlayingXI.deleteMany({
      where: {
        matchId: {
          in: ['live_world_cup_final', 'completed_bilateral_1']
        }
      }
    });

    await prisma.match.deleteMany({
      where: {
        id: {
          in: ['live_world_cup_final', 'completed_bilateral_1']
        }
      }
    });

    await prisma.teamPlayer.deleteMany({
      where: {
        teamId: {
          startsWith: 'uvpce_'
        }
      }
    });

    await prisma.player.deleteMany({
      where: {
        id: {
          startsWith: 'uvpce_'
        }
      }
    });

    await prisma.team.deleteMany({
      where: {
        id: {
          startsWith: 'uvpce_'
        }
      }
    });
    console.log('Cleanup completed.');

    // Seed initial users if empty
    const userCount = await prisma.user.count();
    if (userCount === 0) {
      console.log('Seeding initial users...');
      const adminPassHash = await bcrypt.hash('admin123', 10);
      const userPassHash = await bcrypt.hash('user123', 10);
      const alexPassHash = await bcrypt.hash('alex123', 10);

      await prisma.user.createMany({
        data: [
          { id: 'admin_user', email: 'admin@cricketverse.ai', passwordHash: adminPassHash, role: 'Admin', name: 'Rajesh Kumar' },
          { id: 'user_gmail', email: 'user@gmail.com', passwordHash: userPassHash, role: 'User', name: 'User' },
          { id: 'user_alex', email: 'alex@gmail.com', passwordHash: alexPassHash, role: 'User', name: 'Alex' },
        ],
      });
      console.log('Users seeded.');
    }
  } catch (err) {
    console.error('Error initializing database with Prisma:', err);
  }
}
