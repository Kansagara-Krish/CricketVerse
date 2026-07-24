import { Request, Response } from 'express';
import { pool } from '../config/db';
import { redis, getCachedMatch, setCachedMatch, invalidateCachedMatch } from '../config/redis';

// Helper to construct nested CricketMatch object from raw match row
async function getFullMatchData(matchId: string) {
  const matchRes = await pool.query('SELECT * FROM matches WHERE id = $1', [matchId]);
  if (matchRes.rows.length === 0) return null;
  const raw = matchRes.rows[0];

  // Fetch Team A details
  const teamARes = await pool.query('SELECT * FROM teams WHERE id = $1', [raw.team_a_id]);
  const teamA = teamARes.rows[0];
  const teamAPlayers = await pool.query(
    'SELECT p.* FROM players p JOIN team_players tp ON tp.player_id = p.id WHERE tp.team_id = $1',
    [raw.team_a_id]
  );
  const teamAObj = {
    id: teamA.id,
    name: teamA.name,
    shortName: teamA.short_name,
    logoColorHex: teamA.logo_color_hex,
    players: teamAPlayers.rows.map(p => ({
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
  };

  // Fetch Team B details
  const teamBRes = await pool.query('SELECT * FROM teams WHERE id = $1', [raw.team_b_id]);
  const teamB = teamBRes.rows[0];
  const teamBPlayers = await pool.query(
    'SELECT p.* FROM players p JOIN team_players tp ON tp.player_id = p.id WHERE tp.team_id = $1',
    [raw.team_b_id]
  );
  const teamBObj = {
    id: teamB.id,
    name: teamB.name,
    shortName: teamB.short_name,
    logoColorHex: teamB.logo_color_hex,
    players: teamBPlayers.rows.map(p => ({
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
  };

  // Fetch playing XIs
  const xiARes = await pool.query(
    `SELECT p.* FROM players p 
     JOIN match_playing_xi mxi ON mxi.player_id = p.id 
     WHERE mxi.match_id = $1 AND mxi.team_id = $2`,
    [matchId, raw.team_a_id]
  );
  const xiBRes = await pool.query(
    `SELECT p.* FROM players p 
     JOIN match_playing_xi mxi ON mxi.player_id = p.id 
     WHERE mxi.match_id = $1 AND mxi.team_id = $2`,
    [matchId, raw.team_b_id]
  );

  const formatPlayer = (p: any) => ({
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
  });

  // Fetch ball records
  const ballsRes = await pool.query(
    'SELECT * FROM ball_records WHERE match_id = $1 ORDER BY timestamp ASC',
    [matchId]
  );
  const ballsList = ballsRes.rows.map(b => ({
    run: b.run,
    extraRun: b.extra_run,
    extraType: b.extra_type,
    isWicket: b.is_wicket,
    wicketType: b.wicket_type,
    batsmanName: b.batsman_name,
    bowlerName: b.bowler_name,
    commentary: b.commentary,
    timestamp: b.timestamp.toISOString(),
    strikerId: b.striker_id,
    nonStrikerId: b.non_striker_id,
    bowlerId: b.bowler_id
  }));

  return {
    id: raw.id,
    teamA: teamAObj,
    teamB: teamBObj,
    matchType: raw.match_type,
    venue: raw.venue,
    date: raw.match_date,
    time: raw.match_time,
    status: raw.status,
    tossWinner: raw.toss_winner,
    tossDecision: raw.toss_decision,
    battingTeamId: raw.batting_team_id,
    playingXI_A: xiARes.rows.map(formatPlayer),
    playingXI_B: xiBRes.rows.map(formatPlayer),
    runsA: raw.runs_a,
    wicketsA: raw.wickets_a,
    oversA: parseFloat(raw.overs_a),
    runsB: raw.runs_b,
    wicketsB: raw.wickets_b,
    oversB: parseFloat(raw.overs_b),
    target: raw.target,
    scorerUsername: raw.scorer_username,
    scorerPassword: raw.scorer_password,
    currentStrikerId: raw.current_striker_id,
    currentNonStrikerId: raw.current_non_striker_id,
    currentBowlerId: raw.current_bowler_id,
    balls: ballsList,
    isFirstInnings: raw.is_first_innings
  };
}

export async function getMatches(req: Request, res: Response) {
  try {
    const listRes = await pool.query('SELECT id FROM matches ORDER BY created_at DESC');
    const matches = [];
    for (const row of listRes.rows) {
      // Check cache first for each match
      let matchObj = await getCachedMatch(row.id);
      if (!matchObj) {
        matchObj = await getFullMatchData(row.id);
        if (matchObj) {
          await setCachedMatch(row.id, matchObj);
        }
      }
      if (matchObj) matches.push(matchObj);
    }
    return res.status(200).json(matches);
  } catch (err) {
    console.error('Error fetching matches:', err);
    return res.status(500).json({ error: 'Internal server error.' });
  }
}

export async function getMatchById(req: Request, res: Response) {
  const { id } = req.params;
  try {
    let matchObj = await getCachedMatch(id);
    if (!matchObj) {
      matchObj = await getFullMatchData(id);
      if (matchObj) {
        await setCachedMatch(id, matchObj);
      }
    }
    
    if (!matchObj) {
      return res.status(404).json({ error: 'Match not found.' });
    }
    return res.status(200).json(matchObj);
  } catch (err) {
    console.error('Error fetching match:', err);
    return res.status(500).json({ error: 'Internal server error.' });
  }
}

export async function scheduleMatch(req: Request, res: Response) {
  const { teamAId, teamBId, matchType, venue, date, time, scorerUser, scorerPass } = req.body;

  if (!teamAId || !teamBId || !venue || !date || !time || !scorerUser || !scorerPass) {
    return res.status(400).json({ error: 'All fields are required to schedule a match.' });
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const matchId = `match_${Date.now()}`;
    
    await client.query(
      `INSERT INTO matches (
        id, team_a_id, team_b_id, match_type, venue, match_date, match_time, status, scorer_username, scorer_password
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)`,
      [matchId, teamAId, teamBId, matchType || 'T20', venue, date, time, 'Upcoming', scorerUser, scorerPass]
    );

    // Automatically copy team players to match_playing_xi
    const teamAPlayers = await client.query('SELECT player_id FROM team_players WHERE team_id = $1', [teamAId]);
    for (const p of teamAPlayers.rows) {
      await client.query('INSERT INTO match_playing_xi (match_id, team_id, player_id) VALUES ($1, $2, $3)', [matchId, teamAId, p.player_id]);
    }
    const teamBPlayers = await client.query('SELECT player_id FROM team_players WHERE team_id = $1', [teamBId]);
    for (const p of teamBPlayers.rows) {
      await client.query('INSERT INTO match_playing_xi (match_id, team_id, player_id) VALUES ($1, $2, $3)', [matchId, teamBId, p.player_id]);
    }

    await client.query('COMMIT');
    return res.status(201).json({ message: 'Match scheduled successfully.', id: matchId });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Error scheduling match:', err);
    return res.status(500).json({ error: 'Internal server error.' });
  } finally {
    client.release();
  }
}

export async function adminActivateMatch(req: Request, res: Response) {
  const { id } = req.params;
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const matchRes = await client.query('SELECT * FROM matches WHERE id = $1', [id]);
    if (matchRes.rows.length === 0) {
      return res.status(404).json({ error: 'Match not found.' });
    }
    
    const match = matchRes.rows[0];
    if (match.status === 'Upcoming') {
      // Fetch players to set default active batsmen/bowler
      const batTeamRes = await client.query(
        'SELECT player_id FROM team_players WHERE team_id = $1 ORDER BY player_id ASC LIMIT 2',
        [match.team_a_id]
      );
      const bowlTeamRes = await client.query(
        'SELECT player_id FROM team_players WHERE team_id = $1 ORDER BY player_id DESC LIMIT 1',
        [match.team_b_id]
      );

      const strikerId = batTeamRes.rows.length > 0 ? batTeamRes.rows[0].player_id : '';
      const nonStrikerId = batTeamRes.rows.length > 1 ? batTeamRes.rows[1].player_id : '';
      const bowlerId = bowlTeamRes.rows.length > 0 ? bowlTeamRes.rows[0].player_id : '';

      await client.query(
        `UPDATE matches SET 
          status = 'Live', toss_winner = $1, toss_decision = 'Bat', batting_team_id = $2,
          current_striker_id = $3, current_non_striker_id = $4, current_bowler_id = $5
         WHERE id = $6`,
        [match.team_a_id, match.team_a_id, strikerId, nonStrikerId, bowlerId, id]
      );
    } else {
      await client.query('UPDATE matches SET status = \'Live\' WHERE id = $1', [id]);
    }

    await client.query('COMMIT');
    await invalidateCachedMatch(id);
    return res.status(200).json({ message: 'Match activated to LIVE.' });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Error activating match:', err);
    return res.status(500).json({ error: 'Internal server error.' });
  } finally {
    client.release();
  }
}

export async function resetMatch(req: Request, res: Response) {
  const { id } = req.params;
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const matchRes = await client.query('SELECT * FROM matches WHERE id = $1', [id]);
    if (matchRes.rows.length === 0) {
      return res.status(404).json({ error: 'Match not found.' });
    }
    const match = matchRes.rows[0];

    const batTeamRes = await client.query(
      'SELECT player_id FROM team_players WHERE team_id = $1 ORDER BY player_id ASC LIMIT 2',
      [match.team_a_id]
    );
    const bowlTeamRes = await client.query(
      'SELECT player_id FROM team_players WHERE team_id = $1 ORDER BY player_id DESC LIMIT 1',
      [match.team_b_id]
    );

    const strikerId = batTeamRes.rows.length > 0 ? batTeamRes.rows[0].player_id : '';
    const nonStrikerId = batTeamRes.rows.length > 1 ? batTeamRes.rows[1].player_id : '';
    const bowlerId = bowlTeamRes.rows.length > 0 ? bowlTeamRes.rows[0].player_id : '';

    await client.query(
      `UPDATE matches SET 
        runs_a = 0, wickets_a = 0, overs_a = 0.0,
        runs_b = 0, wickets_b = 0, overs_b = 0.0,
        target = 0, status = 'Upcoming', is_first_innings = true,
        toss_winner = '', toss_decision = '', batting_team_id = '',
        current_striker_id = $1, current_non_striker_id = $2, current_bowler_id = $3
       WHERE id = $4`,
      [strikerId, nonStrikerId, bowlerId, id]
    );

    await client.query('DELETE FROM ball_records WHERE match_id = $1', [id]);
    await client.query('COMMIT');
    await invalidateCachedMatch(id);
    return res.status(200).json({ message: 'Match reset successfully.' });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Error resetting match:', err);
    return res.status(500).json({ error: 'Internal server error.' });
  } finally {
    client.release();
  }
}
