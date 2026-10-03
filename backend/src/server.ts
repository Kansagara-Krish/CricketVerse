import dns from 'dns';
import express from 'express';
import http from 'http';
import cors from 'cors';
import dotenv from 'dotenv';

// Use reliable public DNS for Atlas SRV record resolution across all local ISPs
try {
  dns.setServers(['8.8.8.8', '1.1.1.1']);
} catch (_) {}

import { initDatabase } from './config/db';
import { initSocketIO } from './sockets/socketHandler';

import authRoutes from './routes/authRoutes';
import teamRoutes from './routes/teamRoutes';
import matchRoutes from './routes/matchRoutes';
import scoringRoutes from './routes/scoringRoutes';
import tournamentRoutes from './routes/tournamentRoutes';
import notificationRoutes from './routes/notificationRoutes';
import aiRoutes from './routes/aiRoutes';
import analyticsRoutes from './routes/analyticsRoutes';
import managerRoutes from './routes/managerRoutes';

dotenv.config();

const app = express();
const server = http.createServer(app);
const PORT = process.env.PORT || 3000;

// Enable CORS
app.use(
  cors({
    origin: '*',
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'Accept'],
  })
);

// Body parser
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Base API Routes
app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/teams', teamRoutes);
app.use('/api/v1/matches', matchRoutes);
app.use('/api/v1/scoring', scoringRoutes);
app.use('/api/v1/tournaments', tournamentRoutes);
app.use('/api/v1/notifications', notificationRoutes);
app.use('/api/v1/ai', aiRoutes);
app.use('/api/v1/analytics', analyticsRoutes);
app.use('/api/v1/managers', managerRoutes);

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'OK',
    database: 'MongoDB Atlas',
    timestamp: new Date().toISOString(),
  });
});

// Centralized error handler
app.use((err: any, req: express.Request, res: express.Response, next: express.NextFunction) => {
  console.error('Unhandled server error:', err);
  res.status(err.status || 500).json({
    error: err.message || 'Something went wrong on the server.',
    timestamp: new Date().toISOString(),
  });
});

// 404 handler for unknown endpoints
app.use('*', (req, res) => {
  res.status(404).json({ error: `Cannot ${req.method} ${req.originalUrl}` });
});

// Start servers
async function startServer() {
  try {
    // Initialize MongoDB Atlas connection & seeding
    await initDatabase();

    // Initialize Socket.IO
    initSocketIO(server);

    server.listen(Number(PORT), '0.0.0.0', () => {
      console.log(`🚀 CricketVerse Backend running on http://0.0.0.0:${PORT}`);
      console.log(`📡 Socket.IO initialized and listening for real-time events.`);
    });
  } catch (err) {
    console.error('Failed to start server:', err);
    process.exit(1);
  }
}

startServer();
