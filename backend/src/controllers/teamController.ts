import { Request, Response } from 'express';
import { pool } from '../config/db';
import { redis } from '../config/redis';

// Helper to fetch all teams with their players
async function fetchTeamsWithPlayersFromDB() {
  const teamsQuery = await pool.query('SELECT * FROM teams');
  const teams = teamsQuery.rows;

  const result = [];
  for (const team of teams) {
    const playersQuery = await pool.query(
      `SELECT p.* FROM players p
       JOIN team_players tp ON tp.player_id = p.id
       WHERE tp.team_id = $1`,
      [team.id]
    );
    result.push({
      id: team.id,
      name: team.name,
      shortName: team.short_name,
      logoColorHex: team.logo_color_hex,
      players: playersQuery.rows.map(p => ({
        id: p.id,
        name: p.name,
        role: p.role,
        nationality: p.nationality,
        runsScored: p.runs_scored,
        ballsFaced: p.balls_faced,
        wicketsTaken: p.wickets_taken,
        runsConceded: p.runs_conceded,
        oversBowled: parseFloat(p.overs_bowled),
        matchesPlayed: p.matches_played
      }))
    });
  }
  return result;
}

export async function getTeams(req: Request, res: Response) {
  try {
    // Attempt to load from Redis cache first
    let cached = null;
    if (redis) {
      const cacheVal = await redis.get('teams:all');
      if (cacheVal) {
        cached = JSON.parse(cacheVal);
      }
    }

    if (cached) {
      return res.status(200).json(cached);
    }

    const teams = await fetchTeamsWithPlayersFromDB();
    
    // Save to Redis cache
    if (redis) {
      await redis.set('teams:all', JSON.stringify(teams), 'EX', 86400); // 24 hours
    }

    return res.status(200).json(teams);
  } catch (err) {
    console.error('Error fetching teams:', err);
    return res.status(500).json({ error: 'Internal server error.' });
  }
}

export async function addTeam(req: Request, res: Response) {
  const { name, shortName, logoColorHex, players } = req.body;
  if (!name || !shortName || !logoColorHex) {
    return res.status(400).json({ error: 'Name, short name, and logo color are required.' });
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const teamId = name.toLowerCase().replaceAll(' ', '_');
    
    await client.query(
      'INSERT INTO teams (id, name, short_name, logo_color_hex) VALUES ($1, $2, $3, $4)',
      [teamId, name, shortName, logoColorHex]
    );

    if (Array.isArray(players)) {
      for (const p of players) {
        await client.query(
          `INSERT INTO players (id, name, role, nationality, runs_scored, balls_faced, wickets_taken, runs_conceded, overs_bowled, matches_played) 
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)`,
          [p.id, p.name, p.role, p.nationality || 'IND', p.runsScored || 0, p.ballsFaced || 0, p.wicketsTaken || 0, p.runsConceded || 0, p.oversBowled || 0.0, p.matchesPlayed || 0]
        );
        await client.query(
          'INSERT INTO team_players (team_id, player_id) VALUES ($1, $2)',
          [teamId, p.id]
        );
      }
    }

    await client.query('COMMIT');
    
    // Invalidate Redis cache
    if (redis) {
      await redis.del('teams:all');
    }

    const updatedTeams = await fetchTeamsWithPlayersFromDB();
    if (redis) {
      await redis.set('teams:all', JSON.stringify(updatedTeams), 'EX', 86400);
    }

    return res.status(201).json({ message: 'Team created successfully.', id: teamId });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Error adding team:', err);
    return res.status(500).json({ error: 'Internal server error.' });
  } finally {
    client.release();
  }
}

export async function updateTeam(req: Request, res: Response) {
  const { id } = req.params;
  const { name, shortName, logoColorHex } = req.body;

  try {
    await pool.query(
      'UPDATE teams SET name = $1, short_name = $2, logo_color_hex = $3 WHERE id = $4',
      [name, shortName, logoColorHex, id]
    );

    // Invalidate Redis cache
    if (redis) {
      await redis.del('teams:all');
    }

    return res.status(200).json({ message: 'Team updated successfully.' });
  } catch (err) {
    console.error('Error updating team:', err);
    return res.status(500).json({ error: 'Internal server error.' });
  }
}

export async function deleteTeam(req: Request, res: Response) {
  const { id } = req.params;
  try {
    await pool.query('DELETE FROM teams WHERE id = $1', [id]);
    
    // Invalidate Redis cache
    if (redis) {
      await redis.del('teams:all');
    }

    return res.status(200).json({ message: 'Team deleted successfully.' });
  } catch (err) {
    console.error('Error deleting team:', err);
    return res.status(500).json({ error: 'Internal server error.' });
  }
}

export async function addPlayer(req: Request, res: Response) {
  const { teamId } = req.params;
  const { id, name, role, nationality } = req.body;

  if (!id || !name || !role) {
    return res.status(400).json({ error: 'Player ID, name, and role are required.' });
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query(
      `INSERT INTO players (id, name, role, nationality, runs_scored, balls_faced, wickets_taken, runs_conceded, overs_bowled, matches_played) 
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)`,
      [id, name, role, nationality || 'IND', 0, 0, 0, 0, 0.0, 0]
    );
    await client.query(
      'INSERT INTO team_players (team_id, player_id) VALUES ($1, $2)',
      [teamId, id]
    );
    await client.query('COMMIT');

    // Invalidate Redis cache
    if (redis) {
      await redis.del('teams:all');
    }

    return res.status(201).json({ message: 'Player added to team successfully.' });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Error adding player:', err);
    return res.status(500).json({ error: 'Internal server error.' });
  } finally {
    client.release();
  }
}

export async function updatePlayer(req: Request, res: Response) {
  const { id } = req.params;
  const { name, role, nationality, runsScored, ballsFaced, wicketsTaken, runsConceded, oversBowled, matchesPlayed } = req.body;

  try {
    await pool.query(
      `UPDATE players SET 
        name = $1, role = $2, nationality = $3, runs_scored = $4, balls_faced = $5,
        wickets_taken = $6, runs_conceded = $7, overs_bowled = $8, matches_played = $9
       WHERE id = $10`,
      [name, role, nationality, runsScored, ballsFaced, wicketsTaken, runsConceded, oversBowled, matchesPlayed, id]
    );

    // Invalidate Redis cache
    if (redis) {
      await redis.del('teams:all');
    }

    return res.status(200).json({ message: 'Player updated successfully.' });
  } catch (err) {
    console.error('Error updating player:', err);
    return res.status(500).json({ error: 'Internal server error.' });
  }
}

export async function removePlayer(req: Request, res: Response) {
  const { playerId } = req.params;

  try {
    await pool.query('DELETE FROM players WHERE id = $1', [playerId]);

    // Invalidate Redis cache
    if (redis) {
      await redis.del('teams:all');
    }

    return res.status(200).json({ message: 'Player removed successfully.' });
  } catch (err) {
    console.error('Error removing player:', err);
    return res.status(500).json({ error: 'Internal server error.' });
  }
}
