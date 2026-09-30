import mongoose from 'mongoose';
import dotenv from 'dotenv';
import bcrypt from 'bcryptjs';
import { UserModel } from '../models/User';
import { TeamModel } from '../models/Team';
import { TournamentModel } from '../models/Tournament';

dotenv.config();

const MONGODB_URI = process.env.MONGODB_URI;
const JWT_SECRET = process.env.JWT_SECRET;

export async function initDatabase() {
  if (!MONGODB_URI) {
    console.error('CRITICAL: MONGODB_URI is not defined in environment variables.');
    throw new Error('MONGODB_URI is required.');
  }

  if (!JWT_SECRET) {
    console.warn('WARNING: JWT_SECRET is not explicitly set in .env. Using default fallback for development.');
  }

  try {
    mongoose.set('strictQuery', true);

    await mongoose.connect(MONGODB_URI, {
      serverSelectionTimeoutMS: 15000,
      autoIndex: true,
    });

    console.log('✅ Connected to MongoDB Atlas successfully.');

    // Graceful disconnection handlers
    mongoose.connection.on('error', (err) => {
      console.error('MongoDB connection error occurred:', err);
    });

    mongoose.connection.on('disconnected', () => {
      console.warn('MongoDB connection lost. Reconnecting...');
    });

    // Seed default admin and initial users if empty
    await seedInitialData();

  } catch (err) {
    console.error('❌ Failed to connect to MongoDB Atlas:', err);
    throw err;
  }
}

async function seedInitialData() {
  try {
    const userCount = await UserModel.countDocuments();
    if (userCount === 0) {
      console.log('Seeding initial users into MongoDB Atlas...');
      const adminPassHash = await bcrypt.hash('admin123', 10);
      const userPassHash = await bcrypt.hash('user123', 10);
      const alexPassHash = await bcrypt.hash('alex123', 10);

      await UserModel.create([
        {
          id: 'admin_user',
          email: 'admin@gmail.com',
          passwordHash: adminPassHash,
          role: 'Admin',
          name: 'Rajesh Kumar',
        },
        {
          id: 'user_gmail',
          email: 'user@gmail.com',
          passwordHash: userPassHash,
          role: 'User',
          name: 'User',
        },
        {
          id: 'user_alex',
          email: 'alex@gmail.com',
          passwordHash: alexPassHash,
          role: 'User',
          name: 'Alex',
        },
      ]);
      console.log('✅ Initial users seeded successfully.');
    }
  } catch (err) {
    console.error('Error seeding initial data:', err);
  }
}

// Graceful shutdown
process.on('SIGINT', async () => {
  try {
    await mongoose.connection.close();
    console.log('MongoDB connection closed on app termination (SIGINT).');
    process.exit(0);
  } catch (err) {
    process.exit(1);
  }
});

process.on('SIGTERM', async () => {
  try {
    await mongoose.connection.close();
    console.log('MongoDB connection closed on app termination (SIGTERM).');
    process.exit(0);
  } catch (err) {
    process.exit(1);
  }
});
