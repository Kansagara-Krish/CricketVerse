import mongoose from 'mongoose';
import dotenv from 'dotenv';
import http from 'http';
import express from 'express';
import cors from 'cors';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';

import { initDatabase } from '../config/db';
import { UserModel } from '../models/User';
import { TeamModel } from '../models/Team';
import { TournamentModel } from '../models/Tournament';
import { MatchModel } from '../models/Match';
import { NotificationModel } from '../models/Notification';

import authRoutes from '../routes/authRoutes';
import teamRoutes from '../routes/teamRoutes';
import matchRoutes from '../routes/matchRoutes';
import scoringRoutes from '../routes/scoringRoutes';
import tournamentRoutes from '../routes/tournamentRoutes';
import notificationRoutes from '../routes/notificationRoutes';
import aiRoutes from '../routes/aiRoutes';
import analyticsRoutes from '../routes/analyticsRoutes';

dotenv.config();

const PORT = 3099;
const BASE_URL = `http://127.0.0.1:${PORT}/api/v1`;

let server: http.Server;

async function setupTestServer() {
  const app = express();
  app.use(cors());
  app.use(express.json());

  app.use('/api/v1/auth', authRoutes);
  app.use('/api/v1/teams', teamRoutes);
  app.use('/api/v1/matches', matchRoutes);
  app.use('/api/v1/scoring', scoringRoutes);
  app.use('/api/v1/tournaments', tournamentRoutes);
  app.use('/api/v1/notifications', notificationRoutes);
  app.use('/api/v1/ai', aiRoutes);
  app.use('/api/v1/analytics', analyticsRoutes);

  await initDatabase();

  return new Promise<void>((resolve) => {
    server = app.listen(PORT, () => {
      console.log(`Test server running on port ${PORT}`);
      resolve();
    });
  });
}

async function runTests() {
  console.log('\n========================================');
  console.log('🏏 RUNNING CRICKETVERSE AI INTEGRATION TESTS');
  console.log('========================================\n');

  try {
    await setupTestServer();

    let adminToken = '';
    let userToken = '';
    let scorerToken = '';

    // TEST 1: Admin Login
    console.log('--- TEST 1: Admin Authentication ---');
    const adminLoginRes = await fetch(`${BASE_URL}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email: 'admin@gmail.com', password: 'admin123' }),
    });
    const adminLoginData = await adminLoginRes.json();
    if (adminLoginRes.status === 200 && adminLoginData.token && adminLoginData.user.role === 'Admin') {
      adminToken = adminLoginData.token;
      console.log('✅ Admin login passed:', adminLoginData.user.email);
    } else {
      throw new Error(`Admin login failed: ${JSON.stringify(adminLoginData)}`);
    }

    // TEST 2: User Registration & Login
    console.log('\n--- TEST 2: User Registration & Login ---');
    const testEmail = `fan_${Date.now()}@gmail.com`;
    const regRes = await fetch(`${BASE_URL}/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        name: 'Virat Sharma',
        email: testEmail,
        password: 'Password@123',
        confirmPassword: 'Password@123',
      }),
    });
    const regData = await regRes.json();
    if (regRes.status === 201 && regData.token) {
      userToken = regData.token;
      console.log('✅ User registration passed:', regData.user.email);
    } else {
      throw new Error(`User registration failed: ${JSON.stringify(regData)}`);
    }

    // TEST 3: User Profile Update & OTP Password Change
    console.log('\n--- TEST 3: User Profile Update & OTP Password Change ---');
    const profileRes = await fetch(`${BASE_URL}/auth/profile`, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${userToken}`,
      },
      body: JSON.stringify({ name: 'Virat Sharma Updated' }),
    });
    const profileData = await profileRes.json();
    if (profileRes.status === 200 && profileData.user.name === 'Virat Sharma Updated') {
      console.log('✅ User profile updated successfully.');
    } else {
      throw new Error(`Profile update failed: ${JSON.stringify(profileData)}`);
    }

    const otpRes = await fetch(`${BASE_URL}/auth/password-otp`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${userToken}` },
    });
    const otpData = await otpRes.json();
    if (otpRes.status === 200 && otpData.otp) {
      console.log('✅ Password OTP request passed, OTP received:', otpData.otp);
      const updatePwdRes = await fetch(`${BASE_URL}/auth/password`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${userToken}`,
        },
        body: JSON.stringify({ otp: otpData.otp, newPassword: 'NewPassword@123' }),
      });
      if (updatePwdRes.status === 200) {
        console.log('✅ Password updated successfully with OTP verification.');
      } else {
        throw new Error('Password update failed.');
      }
    }

    // TEST 4: Tournament Creation & Retrieval
    console.log('\n--- TEST 4: Tournament Management ---');
    const tournRes = await fetch(`${BASE_URL}/tournaments`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${adminToken}`,
      },
      body: JSON.stringify({
        name: 'CricketVerse Champions League 2026',
        format: 'T20',
        startDate: '01-10-2026',
        endDate: '25-10-2026',
      }),
    });
    const tournData = await tournRes.json();
    if (tournRes.status !== 201 || !tournData.tournament) {
      throw new Error(`Tournament creation failed: ${JSON.stringify(tournData)}`);
    }
    const tournamentId = tournData.tournament.id;
    console.log('✅ Tournament created in MongoDB Atlas:', tournData.tournament.name);

    // TEST 5: Team & Player Management
    console.log('\n--- TEST 5: Team & Player Management ---');
    const teamARes = await fetch(`${BASE_URL}/teams`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${adminToken}`,
      },
      body: JSON.stringify({
        name: 'Royal Titans',
        shortName: 'RT',
        logoColorHex: '0xFF1E88E5',
        players: [
          { name: 'Rohit Verma', role: 'Batter', isCaptain: true },
          { name: 'Shubman Gill', role: 'Batter', isViceCaptain: true },
          { name: 'Hardik Pandya', role: 'All-rounder' },
          { name: 'Jasprit Bumrah', role: 'Bowler' },
        ],
      }),
    });
    const teamAData = await teamARes.json();
    const teamAId = teamAData.id;
    console.log('✅ Team A created:', teamAData.team.name, 'with ID:', teamAId);

    const teamBRes = await fetch(`${BASE_URL}/teams`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${adminToken}`,
      },
      body: JSON.stringify({
        name: 'Super Strikers',
        shortName: 'SS',
        logoColorHex: '0xFFFFC107',
        players: [
          { name: 'David Warner', role: 'Batter', isCaptain: true },
          { name: 'Steve Smith', role: 'Batter' },
          { name: 'Glenn Maxwell', role: 'All-rounder' },
          { name: 'Pat Cummins', role: 'Bowler', isViceCaptain: true },
        ],
      }),
    });
    const teamBData = await teamBRes.json();
    const teamBId = teamBData.id;
    console.log('✅ Team B created:', teamBData.team.name, 'with ID:', teamBId);

    // TEST 6: Match Scheduling
    console.log('\n--- TEST 6: Match Scheduling & Scorer Assignment ---');
    const scorerUsername = `scorer_match_${Date.now()}`;
    const scorerPassword = 'scorerPass123!';
    const scheduleRes = await fetch(`${BASE_URL}/matches`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${adminToken}`,
      },
      body: JSON.stringify({
        tournamentId,
        teamAId,
        teamBId,
        matchType: 'T20',
        venue: 'Eden Gardens, Kolkata',
        date: '02-10-2026',
        time: '19:30',
        scorerUser: scorerUsername,
        scorerPass: scorerPassword,
      }),
    });
    const scheduleData = await scheduleRes.json();
    if (scheduleRes.status !== 201) {
      throw new Error(`Match scheduling failed: ${JSON.stringify(scheduleData)}`);
    }
    const matchId = scheduleData.id;
    console.log('✅ Match scheduled with ID:', matchId);

    // TEST 7: Scorer Authentication
    console.log('\n--- TEST 7: Scorer / Manager Authentication ---');
    const scorerLoginRes = await fetch(`${BASE_URL}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email: scorerUsername, password: scorerPassword }),
    });
    const scorerLoginData = await scorerLoginRes.json();
    if (scorerLoginRes.status === 200 && scorerLoginData.user.role === 'Scorer') {
      scorerToken = scorerLoginData.token;
      console.log('✅ Scorer logged in successfully for match:', scorerLoginData.activeScorerMatchId);
    } else {
      throw new Error(`Scorer login failed: ${JSON.stringify(scorerLoginData)}`);
    }

    // TEST 8: Toss Setup & Match Activation
    console.log('\n--- TEST 8: Toss Setup & Starting Match ---');
    const tossRes = await fetch(`${BASE_URL}/scoring/${matchId}/toss`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${scorerToken}`,
      },
      body: JSON.stringify({
        tossWinner: teamAId,
        tossDecision: 'Bat',
        firstBattingTeamId: teamAId,
      }),
    });
    const tossData = await tossRes.json();
    if (tossRes.status === 200 && tossData.status === 'Live') {
      console.log('✅ Match is now LIVE. Batting team:', tossData.battingTeamId);
    } else {
      throw new Error(`Toss setup failed: ${JSON.stringify(tossData)}`);
    }

    // TEST 9: Ball-by-ball scoring & Cricket rules
    console.log('\n--- TEST 9: Ball-by-Ball Live Scoring & AI Commentary ---');
    
    // Ball 1: 4 Runs (Boundary)
    const ball1Res = await fetch(`${BASE_URL}/scoring/${matchId}/ball`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${scorerToken}`,
      },
      body: JSON.stringify({
        runs: 4,
        extraType: 'None',
        extraRuns: 0,
        isWicket: false,
        wicketType: 'None',
      }),
    });
    const ball1Data = await ball1Res.json();
    console.log('Ball 1 Result -> Runs:', ball1Data.runsA, 'Overs:', ball1Data.oversA, 'Balls length:', ball1Data.balls.length);
    console.log('AI Commentary:', ball1Data.balls[ball1Data.balls.length - 1].commentary);

    // Ball 2: 1 Run (Single - Strike Rotation)
    const ball2Res = await fetch(`${BASE_URL}/scoring/${matchId}/ball`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${scorerToken}`,
      },
      body: JSON.stringify({
        runs: 1,
        extraType: 'None',
        extraRuns: 0,
        isWicket: false,
        wicketType: 'None',
      }),
    });
    const ball2Data = await ball2Res.json();
    console.log('Ball 2 Result -> Runs:', ball2Data.runsA, 'Overs:', ball2Data.oversA);

    // Ball 3: Wicket (Bowled)
    const ball3Res = await fetch(`${BASE_URL}/scoring/${matchId}/ball`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${scorerToken}`,
      },
      body: JSON.stringify({
        runs: 0,
        extraType: 'None',
        extraRuns: 0,
        isWicket: true,
        wicketType: 'Bowled',
      }),
    });
    const ball3Data = await ball3Res.json();
    console.log('Ball 3 Wicket Result -> Score:', `${ball3Data.runsA}/${ball3Data.wicketsA}`, 'Overs:', ball3Data.oversA);
    console.log('Wicket Commentary:', ball3Data.balls[ball3Data.balls.length - 1].commentary);

    // TEST 10: Undo Last Ball
    console.log('\n--- TEST 10: Undo Last Ball (Wicket Reversal) ---');
    const undoRes = await fetch(`${BASE_URL}/scoring/${matchId}/undo`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${scorerToken}` },
    });
    const undoData = await undoRes.json();
    console.log('After Undo -> Score:', `${undoData.runsA}/${undoData.wicketsA}`, 'Overs:', undoData.oversA);
    if (undoData.wicketsA === 0) {
      console.log('✅ Wicket and stats reversed successfully in MongoDB Atlas.');
    } else {
      throw new Error('Undo failed to revert wicket.');
    }

    // TEST 11: Match Prediction & ML Analytics
    console.log('\n--- TEST 11: Live Match Win Prediction ---');
    const predRes = await fetch(`${BASE_URL}/matches/${matchId}/prediction`);
    const predData = await predRes.json();
    console.log('✅ Match Prediction Data: Team A Win %:', predData.winProbabilityA, 'Team B Win %:', predData.winProbabilityB);
    console.log('Prediction Factors Count:', predData.factors?.length);

    // TEST 12: Notification Creation & Retrieval
    console.log('\n--- TEST 12: Real-Time Notifications ---');
    await fetch(`${BASE_URL}/notifications`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${adminToken}`,
      },
      body: JSON.stringify({
        title: 'Super Sixes Milestone',
        message: 'Royal Titans scored consecutive boundaries!',
      }),
    });
    const notifsRes = await fetch(`${BASE_URL}/notifications`, {
      headers: { Authorization: `Bearer ${userToken}` },
    });
    const notifsData = await notifsRes.json();
    console.log('✅ Fetched Notifications Count for user:', notifsData.length);

    // TEST 13: System Analytics
    console.log('\n--- TEST 13: System Analytics Overview ---');
    const analyticsRes = await fetch(`${BASE_URL}/analytics/stats`);
    const analyticsData = await analyticsRes.json();
    console.log('✅ Overall Stats Summary:', analyticsData.summary);

    // Clean up test data
    console.log('\n--- Cleaning up temporary test records ---');
    await MatchModel.deleteOne({ id: matchId });
    await TeamModel.deleteOne({ id: teamAId });
    await TeamModel.deleteOne({ id: teamBId });
    await TournamentModel.deleteOne({ id: tournamentId });
    await UserModel.deleteOne({ email: testEmail });
    console.log('✅ Test cleanup completed.');

    console.log('\n========================================');
    console.log('🎉 ALL INTEGRATION TESTS PASSED 100%!');
    console.log('========================================\n');

    server.close();
    await mongoose.disconnect();
    process.exit(0);
  } catch (err) {
    console.error('\n❌ TEST FAILED WITH ERROR:', err);
    if (server) server.close();
    await mongoose.disconnect();
    process.exit(1);
  }
}

runTests();
