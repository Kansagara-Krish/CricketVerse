import express from 'express';
import http from 'http';
import cors from 'cors';
import dotenv from 'dotenv';

import { initDatabase } from './config/db';
import { initSocketIO } from './sockets/socketHandler';

import authRoutes from './routes/authRoutes';
import teamRoutes from './routes/teamRoutes';
import matchRoutes from './routes/matchRoutes';
import scoringRoutes from './routes/scoringRoutes';

dotenv.config();

const app = express();
const server = http.createServer(app);
const PORT = process.env.PORT || 3000;

// Enable CORS
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
}));

// Body parser
app.use(express.json());

// Routes
app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/teams', teamRoutes);
app.use('/api/v1/matches', matchRoutes);
app.use('/api/v1/scoring', scoringRoutes);

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'OK', timestamp: new Date() });
});

// Basic error handler
app.use((err: any, req: express.Request, res: express.Response, next: express.NextFunction) => {
  console.error('Unhandled error occurred:', err);
  res.status(500).json({ error: 'Something went wrong on the server.' });
});

// Start servers
async function startServer() {
  // Initialize Database
  await initDatabase();
  
  // Initialize Socket.IO
  initSocketIO(server);

  server.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
  });
}

startServer();
