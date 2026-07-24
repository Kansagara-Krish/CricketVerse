import { Pool } from 'pg';
import dotenv from 'dotenv';
import bcrypt from 'bcryptjs';

dotenv.config();

const databaseUrl = process.env.DATABASE_URL || 'postgresql://postgres:postgres@localhost:5432/cricketverse';

export const pool = new Pool({
  connectionString: databaseUrl,
});

const ddlQuery = `
  CREATE TABLE IF NOT EXISTS users (
    id VARCHAR(255) PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(50) DEFAULT 'FAN'
  );

  CREATE TABLE IF NOT EXISTS tournaments (
    id VARCHAR(255) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    format VARCHAR(50) DEFAULT 'T20',
    start_date DATE,
    end_date DATE
  );

  CREATE TABLE IF NOT EXISTS teams (
    id VARCHAR(255) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    short_name VARCHAR(50) NOT NULL,
    logo_color_hex VARCHAR(50) NOT NULL DEFAULT '0xFF028A6B'
  );

  CREATE TABLE IF NOT EXISTS players (
    id VARCHAR(255) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL,
    nationality VARCHAR(10) DEFAULT 'IND',
    runs_scored INT DEFAULT 0,
    balls_faced INT DEFAULT 0,
    wickets_taken INT DEFAULT 0,
    runs_conceded INT DEFAULT 0,
    overs_bowled NUMERIC(5,1) DEFAULT 0.0,
    matches_played INT DEFAULT 0
  );

  CREATE TABLE IF NOT EXISTS team_players (
    team_id VARCHAR(255) REFERENCES teams(id) ON DELETE CASCADE,
    player_id VARCHAR(255) REFERENCES players(id) ON DELETE CASCADE,
    PRIMARY KEY (team_id, player_id)
  );

  CREATE TABLE IF NOT EXISTS matches (
    id VARCHAR(255) PRIMARY KEY,
    tournament_id VARCHAR(255) REFERENCES tournaments(id) ON DELETE SET NULL,
    team_a_id VARCHAR(255) REFERENCES teams(id) ON DELETE CASCADE,
    team_b_id VARCHAR(255) REFERENCES teams(id) ON DELETE CASCADE,
    match_type VARCHAR(50) DEFAULT 'T20',
    venue VARCHAR(255) NOT NULL,
    match_date VARCHAR(50) NOT NULL,
    match_time VARCHAR(50) NOT NULL,
    status VARCHAR(50) DEFAULT 'UPCOMING',
    toss_winner VARCHAR(255) DEFAULT '',
    toss_decision VARCHAR(50) DEFAULT '',
    batting_team_id VARCHAR(255) DEFAULT '',
    runs_a INT DEFAULT 0,
    wickets_a INT DEFAULT 0,
    overs_a NUMERIC(4,1) DEFAULT 0.0,
    runs_b INT DEFAULT 0,
    wickets_b INT DEFAULT 0,
    overs_b NUMERIC(4,1) DEFAULT 0.0,
    target INT DEFAULT 0,
    is_first_innings BOOLEAN DEFAULT TRUE,
    current_striker_id VARCHAR(255) DEFAULT '',
    current_non_striker_id VARCHAR(255) DEFAULT '',
    current_bowler_id VARCHAR(255) DEFAULT '',
    scorer_username VARCHAR(100) NOT NULL,
    scorer_password VARCHAR(255) NOT NULL
  );

  CREATE TABLE IF NOT EXISTS match_playing_xi (
    match_id VARCHAR(255) REFERENCES matches(id) ON DELETE CASCADE,
    team_id VARCHAR(255) REFERENCES teams(id) ON DELETE CASCADE,
    player_id VARCHAR(255) REFERENCES players(id) ON DELETE CASCADE,
    PRIMARY KEY (match_id, team_id, player_id)
  );

  CREATE TABLE IF NOT EXISTS ball_records (
    id SERIAL PRIMARY KEY,
    match_id VARCHAR(255) REFERENCES matches(id) ON DELETE CASCADE,
    run INT DEFAULT 0,
    extra_run INT DEFAULT 0,
    extra_type VARCHAR(50) DEFAULT 'None',
    is_wicket BOOLEAN DEFAULT FALSE,
    wicket_type VARCHAR(50) DEFAULT 'None',
    batsman_name VARCHAR(255) NOT NULL,
    bowler_name VARCHAR(255) NOT NULL,
    commentary TEXT NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    striker_id VARCHAR(255),
    non_striker_id VARCHAR(255),
    bowler_id VARCHAR(255)
  );
`;

export async function initDatabase() {
  try {
    const client = await pool.connect();
    console.log('Connected to PostgreSQL successfully.');
    
    // Execute DDL query
    await client.query(ddlQuery);
    console.log('Database tables verified/created.');
    
    // Seed initial users if empty
    const userCountRes = await client.query('SELECT COUNT(*) FROM users');
    const userCount = parseInt(userCountRes.rows[0].count, 10);
    if (userCount === 0) {
      console.log('Seeding initial users...');
      const adminPassHash = await bcrypt.hash('admin123', 10);
      const userPassHash = await bcrypt.hash('user123', 10);
      const alexPassHash = await bcrypt.hash('alex123', 10);
      
      await client.query(
        'INSERT INTO users (id, email, password_hash, role) VALUES ($1, $2, $3, $4)',
        ['admin_user', 'admin@cricketverse.ai', adminPassHash, 'Admin']
      );
      await client.query(
        'INSERT INTO users (id, email, password_hash, role) VALUES ($1, $2, $3, $4)',
        ['user_gmail', 'user@gmail.com', userPassHash, 'User']
      );
      await client.query(
        'INSERT INTO users (id, email, password_hash, role) VALUES ($1, $2, $3, $4)',
        ['user_alex', 'alex@gmail.com', alexPassHash, 'User']
      );
      console.log('Users seeded.');
    }
    
    // Seed default teams and players if empty
    const teamCountRes = await client.query('SELECT COUNT(*) FROM teams');
    const teamCount = parseInt(teamCountRes.rows[0].count, 10);
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
        await client.query(
          'INSERT INTO teams (id, name, short_name, logo_color_hex) VALUES ($1, $2, $3, $4)',
          [t.id, t.name, t.shortName, t.logoColorHex]
        );
        
        const roles = ['Batter', 'Batter', 'Batter', 'Batter', 'All-rounder', 'All-rounder', 'All-rounder', 'Bowler', 'Bowler', 'Bowler', 'Bowler'];
        for (let i = 0; i < 11; i++) {
          const fName = firstNames[(t.startIndex + i) % firstNames.length];
          const lName = lastNames[(t.startIndex * 3 + i) % lastNames.length];
          const fullName = `${fName} ${lName}`;
          const pId = `${t.id.toLowerCase()}_${fName.toLowerCase()}_${i}`;
          
          const runs = (200 + (t.startIndex * 35 + i * 55) % 1800);
          const wickets = (i >= 7) ? (10 + (t.startIndex * 4 + i * 5) % 50) : (0 + (t.startIndex + i) % 4);
          const matches = 15 + Math.floor(runs / 120);
          
          await client.query(
            'INSERT INTO players (id, name, role, nationality, runs_scored, balls_faced, wickets_taken, matches_played) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)',
            [pId, fullName, roles[i], 'IND', runs, Math.round(runs * 1.3), wickets, matches]
          );
          
          await client.query(
            'INSERT INTO team_players (team_id, player_id) VALUES ($1, $2)',
            [t.id, pId]
          );
        }
      }
      console.log('Teams and players seeded.');
    }

    // Seed default matches if empty
    const matchCountRes = await client.query('SELECT COUNT(*) FROM matches');
    const matchCount = parseInt(matchCountRes.rows[0].count, 10);
    if (matchCount === 0) {
      console.log('Seeding default matches...');
      
      // Live Match: Titans vs Warriors
      await client.query(
        `INSERT INTO matches (
          id, team_a_id, team_b_id, match_type, venue, date, time, status, 
          toss_winner, toss_decision, batting_team_id, runs_a, wickets_a, overs_a,
          runs_b, wickets_b, overs_b, target, scorer_username, scorer_password,
          current_striker_id, current_non_striker_id, current_bowler_id, is_first_innings
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22, $23, $24)`,
        [
          'live_world_cup_final', 'uvpce_titans', 'uvpce_warriors', 'T20', 'Narendra Modi Stadium', '17-07-2026', '19:30', 'Live',
          'UVPCE - Titans', 'Bat', 'uvpce_titans', 145, 4, 15.4,
          0, 0, 0.0, 185, 'scorer1', '123',
          'uvpce_titans_aarav_0', 'uvpce_titans_vihaan_1', 'uvpce_warriors_rudra_10', true
        ]
      );
      
      // Add live match players to match_playing_xi
      const titansPlayers = await client.query('SELECT player_id FROM team_players WHERE team_id = \'uvpce_titans\'');
      for (const p of titansPlayers.rows) {
        await client.query('INSERT INTO match_playing_xi (match_id, team_id, player_id) VALUES ($1, $2, $3)', ['live_world_cup_final', 'uvpce_titans', p.player_id]);
      }
      const warriorsPlayers = await client.query('SELECT player_id FROM team_players WHERE team_id = \'uvpce_warriors\'');
      for (const p of warriorsPlayers.rows) {
        await client.query('INSERT INTO match_playing_xi (match_id, team_id, player_id) VALUES ($1, $2, $3)', ['live_world_cup_final', 'uvpce_warriors', p.player_id]);
      }
      
      // Completed Match: UVPCE A vs UVPCE B
      await client.query(
        `INSERT INTO matches (
          id, team_a_id, team_b_id, match_type, venue, date, time, status, 
          toss_winner, toss_decision, batting_team_id, runs_a, wickets_a, overs_a,
          runs_b, wickets_b, overs_b, target, scorer_username, scorer_password, is_first_innings
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21)`,
        [
          'completed_bilateral_1', 'uvpce_a', 'uvpce_b', 'T20', 'Wankhede Stadium', '15-07-2026', '14:30', 'Completed',
          'UVPCE - B', 'Bowl', 'uvpce_a', 168, 6, 20.0,
          169, 5, 19.3, 169, 'scorer2', '456', false
        ]
      );
      
      // Add completed match players to match_playing_xi
      const aPlayers = await client.query('SELECT player_id FROM team_players WHERE team_id = \'uvpce_a\'');
      for (const p of aPlayers.rows) {
        await client.query('INSERT INTO match_playing_xi (match_id, team_id, player_id) VALUES ($1, $2, $3)', ['completed_bilateral_1', 'uvpce_a', p.player_id]);
      }
      const bPlayers = await client.query('SELECT player_id FROM team_players WHERE team_id = \'uvpce_b\'');
      for (const p of bPlayers.rows) {
        await client.query('INSERT INTO match_playing_xi (match_id, team_id, player_id) VALUES ($1, $2, $3)', ['completed_bilateral_1', 'uvpce_b', p.player_id]);
      }
      
      console.log('Matches seeded.');
    }
    
    client.release();
  } catch (err) {
    console.error('Error initializing database:', err);
  }
}
