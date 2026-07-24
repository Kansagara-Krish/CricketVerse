import { Request, Response } from 'express';
import { pool } from '../config/db';
import { invalidateCachedMatch, getCachedMatch, setCachedMatch } from '../config/redis';
import { broadcastMatchUpdate } from '../sockets/socketHandler';

// Helper to fetch and rebuild match data to broadcast/return
async function getFullMatchData(matchId: string) {
  const matchRes = await pool.query('SELECT * FROM matches WHERE id = $1', [matchId]);
  if (matchRes.rows.length === 0) return null;
  const raw = matchRes.rows[0];

  // Fetch Team A
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

  // Fetch Team B
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

  // Fetch XIs
  const xiARes = await pool.query(
    `SELECT p.* FROM players p JOIN match_playing_xi mxi ON mxi.player_id = p.id 
     WHERE mxi.match_id = $1 AND mxi.team_id = $2`,
    [matchId, raw.team_a_id]
  );
  const xiBRes = await pool.query(
    `SELECT p.* FROM players p JOIN match_playing_xi mxi ON mxi.player_id = p.id 
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

function incrementOvers(currentOvers: number, ballsAdded: number): number {
  if (ballsAdded === 0) return currentOvers;
  let oversInt = Math.floor(currentOvers);
  let ballsInt = Math.round((currentOvers - oversInt) * 10);
  
  ballsInt += ballsAdded;
  if (ballsInt >= 6) {
    oversInt += Math.floor(ballsInt / 6);
    ballsInt = ballsInt % 6;
  }
  return parseFloat((oversInt + (ballsInt / 10.0)).toFixed(1));
}

function decrementOvers(currentOvers: number, ballsRemoved: number): number {
  if (ballsRemoved === 0) return currentOvers;
  let oversInt = Math.floor(currentOvers);
  let ballsInt = Math.round((currentOvers - oversInt) * 10);
  
  ballsInt -= ballsRemoved;
  if (ballsInt < 0) {
    const oversNeeded = Math.ceil(Math.abs(ballsInt) / 6);
    oversInt -= oversNeeded;
    ballsInt = (ballsInt + (oversNeeded * 6)) % 6;
    if (oversInt < 0) {
      oversInt = 0;
      ballsInt = 0;
    }
  }
  return parseFloat((oversInt + (ballsInt / 10.0)).toFixed(1));
}

function generateAICommentary(batsman: string, bowler: string, runs: number, extraType: string, isWicket: boolean, wicketType: string): string {
  const selectRandom = (arr: string[]) => arr[Math.floor(Math.random() * arr.length)];

  if (isWicket) {
    const wicketTpls = [
      `OUT! ${bowler} strikes! ${batsman} tries to smash it but is clean bowled! Brilliant delivery!`,
      `CAUGHT! In the air... and taken! ${batsman} goes for the big one off ${bowler}, but finds the fielder at deep midwicket.`,
      `LBW! Huge shout from ${bowler}, and the finger goes up! ${batsman} is trapped right in front of the stumps.`,
      `RUN OUT! Sensational fielding! Direct hit from point and ${batsman} is yards short of the crease!`,
    ];
    return selectRandom(wicketTpls);
  }

  if (extraType === 'Wide') {
    return `Wide ball! ${bowler} strays down the leg side, ${batsman} lets it go. Extra run to the total.`;
  }
  if (extraType === 'No Ball') {
    return `No Ball! ${bowler} oversteps the crease. That's an extra run and a Free Hit for ${batsman}!`;
  }

  if (runs === 6) {
    const sixTpls = [
      `SIX! ${batsman} steps out and launches ${bowler} high over long-on! That has gone miles!`,
      `MAXIMUM! Incredibly struck by ${batsman}! Picked up off the pads and dispatched into the crowd!`,
      `SIX MORE! ${batsman} displays pure class, a sweet pull shot that sails comfortably over deep square leg.`,
    ];
    return selectRandom(sixTpls);
  }
  if (runs === 4) {
    const fourTpls = [
      `FOUR! Beautiful shot by ${batsman}. Edges past slip and races away to the third man boundary.`,
      `CRACKING BOUNDARY! ${batsman} stands tall and drives ${bowler} through extra cover for four.`,
      `FOUR RUNS! Short and wide from ${bowler}, cut away elegantly by ${batsman} to the fence.`,
    ];
    return selectRandom(fourTpls);
  }
  if (runs === 0) {
    const dotTpls = [
      `No run. Good length delivery from ${bowler}, played defensively back to the bowler.`,
      `Dot ball. ${batsman} swings and misses a slower delivery from ${bowler}.`,
      `Well bowled! ${bowler} beats ${batsman} outside the off stump with a beautiful outswinger.`,
    ];
    return selectRandom(dotTpls);
  }

  const runTpls = [
    `Just a single. ${batsman} drives it down to long-off to rotate the strike.`,
    `Tucked away off the hips by ${batsman}, they scamper back for a quick couple of runs.`,
    `Placed softly into the gap at cover by ${batsman}, allowing a quick single.`,
  ];
  return selectRandom(runTpls);
}

export async function startMatchSetup(req: Request, res: Response) {
  const { matchId } = req.params;
  const { tossWinner, tossDecision, firstBattingTeamId } = req.body;

  if (!tossWinner || !tossDecision || !firstBattingTeamId) {
    return res.status(400).json({ error: 'Toss winner, decision, and batting team are required.' });
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    
    const matchRes = await client.query('SELECT * FROM matches WHERE id = $1', [matchId]);
    if (matchRes.rows.length === 0) {
      return res.status(404).json({ error: 'Match not found.' });
    }
    const match = matchRes.rows[0];

    const isTeamAFirst = firstBattingTeamId === match.team_a_id;
    const batTeamId = isTeamAFirst ? match.team_a_id : match.team_b_id;
    const bowlTeamId = isTeamAFirst ? match.team_b_id : match.team_a_id;

    // Get first 2 players from batting team as striker/non-striker
    const batPlayersRes = await client.query(
      'SELECT player_id FROM team_players WHERE team_id = $1 ORDER BY player_id ASC LIMIT 2',
      [batTeamId]
    );
    const strikerId = batPlayersRes.rows.length > 0 ? batPlayersRes.rows[0].player_id : '';
    const nonStrikerId = batPlayersRes.rows.length > 1 ? batPlayersRes.rows[1].player_id : '';

    // Get last player from bowling team as bowler
    const bowlPlayersRes = await client.query(
      'SELECT player_id FROM team_players WHERE team_id = $1 ORDER BY player_id DESC LIMIT 1',
      [bowlTeamId]
    );
    const bowlerId = bowlPlayersRes.rows.length > 0 ? bowlPlayersRes.rows[0].player_id : '';

    await client.query(
      `UPDATE matches SET 
        status = 'Live', toss_winner = $1, toss_decision = $2, batting_team_id = $3,
        current_striker_id = $4, current_non_striker_id = $5, current_bowler_id = $6
       WHERE id = $7`,
      [tossWinner, tossDecision, batTeamId, strikerId, nonStrikerId, bowlerId, matchId]
    );

    await client.query('COMMIT');
    await invalidateCachedMatch(matchId);
    
    const updatedMatch = await getFullMatchData(matchId);
    if (updatedMatch) {
      await setCachedMatch(matchId, updatedMatch);
      broadcastMatchUpdate(matchId, 'match_update', updatedMatch);
    }

    return res.status(200).json(updatedMatch);
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Error starting match setup:', err);
    return res.status(500).json({ error: 'Internal server error.' });
  } finally {
    client.release();
  }
}

export async function updateScore(req: Request, res: Response) {
  const { matchId } = req.params;
  const { runs, extraType, extraRuns, isWicket, wicketType, dismissedPlayerId, newBatsmanId, newBatsmanPosition } = req.body;

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    
    const matchRes = await client.query('SELECT * FROM matches WHERE id = $1', [matchId]);
    if (matchRes.rows.length === 0) {
      return res.status(404).json({ error: 'Match not found.' });
    }
    const match = matchRes.rows[0];

    const currentStrikerIdBefore = match.current_striker_id;
    const currentNonStrikerIdBefore = match.current_non_striker_id;
    const currentBowlerIdBefore = match.current_bowler_id;

    // Fetch striker and bowler details
    const strikerRes = await client.query('SELECT name, runs_scored, balls_faced FROM players WHERE id = $1', [currentStrikerIdBefore]);
    const striker = strikerRes.rows[0];
    const bowlerRes = await client.query('SELECT name, runs_conceded, wickets_taken, overs_bowled FROM players WHERE id = $1', [currentBowlerIdBefore]);
    const bowler = bowlerRes.rows[0];

    let ballVal = 1;
    if (extraType === 'Wide' || extraType === 'No Ball') {
      ballVal = 0;
    }

    const totalRunsThisBall = runs + extraRuns;
    let runsA = match.runs_a;
    let wicketsA = match.wickets_a;
    let oversA = parseFloat(match.overs_a);
    let runsB = match.runs_b;
    let wicketsB = match.wickets_b;
    let oversB = parseFloat(match.overs_b);

    if (match.is_first_innings) {
      runsA += totalRunsThisBall;
      if (isWicket && wicketType !== 'Retired Hurt') wicketsA += 1;
      oversA = incrementOvers(oversA, ballVal);
    } else {
      runsB += totalRunsThisBall;
      if (isWicket && wicketType !== 'Retired Hurt') wicketsB += 1;
      oversB = incrementOvers(oversB, ballVal);
    }

    // Update Player Batting Stats
    if (extraType === 'None' || extraType === 'Leg Bye') {
      const newRuns = striker.runs_scored + runs;
      const newBalls = striker.balls_faced + ballVal;
      await client.query(
        'UPDATE players SET runs_scored = $1, balls_faced = $2 WHERE id = $3',
        [newRuns, newBalls, currentStrikerIdBefore]
      );
    }

    // Update Bowler Stats
    const newConceded = bowler.runs_conceded + totalRunsThisBall;
    let newWickets = bowler.wickets_taken;
    if (isWicket && wicketType !== 'Run Out' && wicketType !== 'Retired Out' && wicketType !== 'Retired Hurt') {
      newWickets += 1;
    }
    let newOversBowled = parseFloat(bowler.overs_bowled);
    if (ballVal > 0) {
      newOversBowled = incrementOvers(newOversBowled, 1);
    }
    await client.query(
      'UPDATE players SET runs_conceded = $1, wickets_taken = $2, overs_bowled = $3 WHERE id = $4',
      [newConceded, newWickets, newOversBowled, currentBowlerIdBefore]
    );

    // AI Commentary
    const commentary = generateAICommentary(striker.name, bowler.name, runs, extraType, isWicket, wicketType);

    // Save Ball Record with Snapshots
    await client.query(
      `INSERT INTO ball_records (
        match_id, run, extra_run, extra_type, is_wicket, wicket_type, batsman_name, bowler_name, commentary, striker_id, non_striker_id, bowler_id
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)`,
      [matchId, runs, extraRuns, extraType, isWicket, wicketType, striker.name, bowler.name, commentary, currentStrikerIdBefore, currentNonStrikerIdBefore, currentBowlerIdBefore]
    );

    // Strike rotation on odd runs (1, 3, 5)
    let finalStrikerId = currentStrikerIdBefore;
    let finalNonStrikerId = currentNonStrikerIdBefore;
    if (runs % 2 !== 0 && (extraType === 'None' || extraType === 'Leg Bye')) {
      finalStrikerId = currentNonStrikerIdBefore;
      finalNonStrikerId = currentStrikerIdBefore;
    }

    // Wicket handling
    if (isWicket) {
      const activeWickets = match.is_first_innings ? wicketsA : wicketsB;
      const partnerId = (dismissedPlayerId === currentStrikerIdBefore) ? currentNonStrikerIdBefore : currentStrikerIdBefore;

      if (newBatsmanId) {
        if (newBatsmanPosition === 'Striker') {
          finalStrikerId = newBatsmanId;
          finalNonStrikerId = partnerId;
        } else {
          finalStrikerId = partnerId;
          finalNonStrikerId = newBatsmanId;
        }
      } else {
        // Auto select next player from team list if not provided
        const battingTeamId = match.batting_team_id;
        const nextPlayerRes = await client.query(
          `SELECT p.id FROM players p 
           JOIN team_players tp ON tp.player_id = p.id 
           WHERE tp.team_id = $1 AND p.id NOT IN (
             SELECT DISTINCT striker_id FROM ball_records WHERE match_id = $2
             UNION SELECT DISTINCT non_striker_id FROM ball_records WHERE match_id = $2
           ) LIMIT 1`,
          [battingTeamId, matchId]
        );
        if (nextPlayerRes.rows.length > 0) {
          const nextPlayerId = nextPlayerRes.rows[0].id;
          if (dismissedPlayerId === currentNonStrikerIdBefore) {
            finalNonStrikerId = nextPlayerId;
          } else {
            finalStrikerId = nextPlayerId;
          }
        }
      }
    }

    await client.query(
      `UPDATE matches SET 
        runs_a = $1, wickets_a = $2, overs_a = $3,
        runs_b = $4, wickets_b = $5, overs_b = $6,
        current_striker_id = $7, current_non_striker_id = $8
       WHERE id = $9`,
      [runsA, wicketsA, oversA, runsB, wicketsB, oversB, finalStrikerId, finalNonStrikerId, matchId]
    );

    // If wickets = 10, trigger innings/match end
    const finalWickets = match.is_first_innings ? wicketsA : wicketsB;
    if (finalWickets >= 10) {
      // Trigger Innings complete logic inside transaction
      if (match.is_first_innings) {
        const nextBatTeamId = match.batting_team_id === match.team_a_id ? match.team_b_id : match.team_a_id;
        const nextBatPlayers = await client.query(
          'SELECT player_id FROM team_players WHERE team_id = $1 ORDER BY player_id ASC LIMIT 2',
          [nextBatTeamId]
        );
        const nextBowlPlayers = await client.query(
          'SELECT player_id FROM team_players WHERE team_id = $1 ORDER BY player_id DESC LIMIT 1',
          [match.batting_team_id]
        );

        const nextStriker = nextBatPlayers.rows.length > 0 ? nextBatPlayers.rows[0].player_id : '';
        const nextNonStriker = nextBatPlayers.rows.length > 1 ? nextBatPlayers.rows[1].player_id : '';
        const nextBowler = nextBowlPlayers.rows.length > 0 ? nextBowlPlayers.rows[0].player_id : '';

        await client.query(
          `UPDATE matches SET 
            is_first_innings = false, batting_team_id = $1, target = $2,
            current_striker_id = $3, current_non_striker_id = $4, current_bowler_id = $5
           WHERE id = $6`,
          [nextBatTeamId, runsA + 1, nextStriker, nextNonStriker, nextBowler, matchId]
        );
      } else {
        await client.query('UPDATE matches SET status = \'Completed\' WHERE id = $1', [matchId]);
      }
    }

    await client.query('COMMIT');
    await invalidateCachedMatch(matchId);

    const updatedMatch = await getFullMatchData(matchId);
    if (updatedMatch) {
      await setCachedMatch(matchId, updatedMatch);
      broadcastMatchUpdate(matchId, 'match_update', updatedMatch);
    }

    return res.status(200).json(updatedMatch);
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Error updating score:', err);
    return res.status(500).json({ error: 'Internal server error.' });
  } finally {
    client.release();
  }
}

export async function undoLastBall(req: Request, res: Response) {
  const { matchId } = req.params;
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const matchRes = await client.query('SELECT * FROM matches WHERE id = $1', [matchId]);
    if (matchRes.rows.length === 0) {
      return res.status(404).json({ error: 'Match not found.' });
    }
    const match = matchRes.rows[0];

    // Find last ball record
    const ballsRes = await client.query('SELECT * FROM ball_records WHERE match_id = $1 ORDER BY id DESC LIMIT 1', [matchId]);
    if (ballsRes.rows.length === 0) {
      return res.status(400).json({ error: 'No balls recorded yet.' });
    }
    const lastBall = ballsRes.rows[0];

    // Restore state from snapshot
    const strikerId = lastBall.striker_id;
    const nonStrikerId = lastBall.non_striker_id;
    const bowlerId = lastBall.bowler_id;

    // Fetch players
    const strikerRes = await client.query('SELECT runs_scored, balls_faced FROM players WHERE id = $1', [strikerId]);
    const striker = strikerRes.rows[0];
    const bowlerRes = await client.query('SELECT runs_conceded, wickets_taken, overs_bowled FROM players WHERE id = $1', [bowlerId]);
    const bowler = bowlerRes.rows[0];

    const ballVal = (lastBall.extra_type === 'Wide' || lastBall.extra_type === 'No Ball') ? 0 : 1;
    const totalRunsThisBall = lastBall.run + lastBall.extra_run;

    let runsA = match.runs_a;
    let wicketsA = match.wickets_a;
    let oversA = parseFloat(match.overs_a);
    let runsB = match.runs_b;
    let wicketsB = match.wickets_b;
    let oversB = parseFloat(match.overs_b);
    let status = match.status;

    if (match.is_first_innings) {
      runsA = Math.max(0, runsA - totalRunsThisBall);
      if (lastBall.is_wicket && lastBall.wicket_type !== 'Retired Hurt') {
        wicketsA = Math.max(0, wicketsA - 1);
      }
      oversA = decrementOvers(oversA, ballVal);
    } else {
      runsB = Math.max(0, runsB - totalRunsThisBall);
      if (lastBall.is_wicket && lastBall.wicket_type !== 'Retired Hurt') {
        wicketsB = Math.max(0, wicketsB - 1);
      }
      oversB = decrementOvers(oversB, ballVal);
    }

    if (status === 'Completed') {
      status = 'Live';
    }

    // Revert Player Batting Stats
    if (lastBall.extra_type === 'None' || lastBall.extra_type === 'Leg Bye') {
      const newRuns = Math.max(0, striker.runs_scored - lastBall.run);
      const newBalls = Math.max(0, striker.balls_faced - ballVal);
      await client.query(
        'UPDATE players SET runs_scored = $1, balls_faced = $2 WHERE id = $3',
        [newRuns, newBalls, strikerId]
      );
    }

    // Revert Bowler Stats
    const newConceded = Math.max(0, bowler.runs_conceded - totalRunsThisBall);
    let newWickets = bowler.wickets_taken;
    if (lastBall.is_wicket && lastBall.wicket_type !== 'Run Out' && lastBall.wicket_type !== 'Retired Out' && lastBall.wicket_type !== 'Retired Hurt') {
      newWickets = Math.max(0, newWickets - 1);
    }
    let newOversBowled = parseFloat(bowler.overs_bowled);
    if (ballVal > 0) {
      newOversBowled = decrementOvers(newOversBowled, 1);
    }
    await client.query(
      'UPDATE players SET runs_conceded = $1, wickets_taken = $2, overs_bowled = $3 WHERE id = $4',
      [newConceded, newWickets, newOversBowled, bowlerId]
    );

    // Delete ball record
    await client.query('DELETE FROM ball_records WHERE id = $1', [lastBall.id]);

    // Save restored match state
    await client.query(
      `UPDATE matches SET 
        runs_a = $1, wickets_a = $2, overs_a = $3,
        runs_b = $4, wickets_b = $5, overs_b = $6,
        current_striker_id = $7, current_non_striker_id = $8, current_bowler_id = $9, status = $10
       WHERE id = $11`,
      [runsA, wicketsA, oversA, runsB, wicketsB, oversB, strikerId, nonStrikerId, bowlerId, status, matchId]
    );

    await client.query('COMMIT');
    await invalidateCachedMatch(matchId);

    const updatedMatch = await getFullMatchData(matchId);
    if (updatedMatch) {
      await setCachedMatch(matchId, updatedMatch);
      broadcastMatchUpdate(matchId, 'match_update', updatedMatch);
    }

    return res.status(200).json(updatedMatch);
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Error in undo last ball:', err);
    return res.status(500).json({ error: 'Internal server error.' });
  } finally {
    client.release();
  }
}

export async function swapStrikers(req: Request, res: Response) {
  const { matchId } = req.params;
  try {
    const matchRes = await pool.query('SELECT current_striker_id, current_non_striker_id FROM matches WHERE id = $1', [matchId]);
    if (matchRes.rows.length === 0) {
      return res.status(404).json({ error: 'Match not found.' });
    }
    const match = matchRes.rows[0];
    
    await pool.query(
      'UPDATE matches SET current_striker_id = $1, current_non_striker_id = $2 WHERE id = $3',
      [match.current_non_striker_id, match.current_striker_id, matchId]
    );

    await invalidateCachedMatch(matchId);
    const updatedMatch = await getFullMatchData(matchId);
    if (updatedMatch) {
      await setCachedMatch(matchId, updatedMatch);
      broadcastMatchUpdate(matchId, 'match_update', updatedMatch);
    }

    return res.status(200).json(updatedMatch);
  } catch (err) {
    console.error('Error swapping strikers:', err);
    return res.status(500).json({ error: 'Internal server error.' });
  }
}

export async function switchBowler(req: Request, res: Response) {
  const { matchId } = req.params;
  const { bowlerId } = req.body;

  if (!bowlerId) {
    return res.status(400).json({ error: 'Bowler ID is required.' });
  }

  try {
    await pool.query('UPDATE matches SET current_bowler_id = $1 WHERE id = $2', [bowlerId, matchId]);
    await invalidateCachedMatch(matchId);
    
    const updatedMatch = await getFullMatchData(matchId);
    if (updatedMatch) {
      await setCachedMatch(matchId, updatedMatch);
      broadcastMatchUpdate(matchId, 'match_update', updatedMatch);
    }

    return res.status(200).json(updatedMatch);
  } catch (err) {
    console.error('Error switching bowler:', err);
    return res.status(500).json({ error: 'Internal server error.' });
  }
}

export async function endInningsOrMatch(req: Request, res: Response) {
  const { matchId } = req.params;
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const matchRes = await client.query('SELECT * FROM matches WHERE id = $1', [matchId]);
    if (matchRes.rows.length === 0) {
      return res.status(404).json({ error: 'Match not found.' });
    }
    const match = matchRes.rows[0];

    if (match.is_first_innings) {
      const nextBatTeamId = match.batting_team_id === match.team_a_id ? match.team_b_id : match.team_a_id;
      
      const nextBatPlayers = await client.query(
        'SELECT player_id FROM team_players WHERE team_id = $1 ORDER BY player_id ASC LIMIT 2',
        [nextBatTeamId]
      );
      const nextBowlPlayers = await client.query(
        'SELECT player_id FROM team_players WHERE team_id = $1 ORDER BY player_id DESC LIMIT 1',
        [match.batting_team_id]
      );

      const nextStriker = nextBatPlayers.rows.length > 0 ? nextBatPlayers.rows[0].player_id : '';
      const nextNonStriker = nextBatPlayers.rows.length > 1 ? nextBatPlayers.rows[1].player_id : '';
      const nextBowler = nextBowlPlayers.rows.length > 0 ? nextBowlPlayers.rows[0].player_id : '';

      await client.query(
        `UPDATE matches SET 
          is_first_innings = false, batting_team_id = $1, target = $2,
          current_striker_id = $3, current_non_striker_id = $4, current_bowler_id = $5
         WHERE id = $6`,
        [nextBatTeamId, match.runs_a + 1, nextStriker, nextNonStriker, nextBowler, matchId]
      );
    } else {
      await client.query('UPDATE matches SET status = \'Completed\' WHERE id = $1', [matchId]);
    }

    await client.query('COMMIT');
    await invalidateCachedMatch(matchId);

    const updatedMatch = await getFullMatchData(matchId);
    if (updatedMatch) {
      await setCachedMatch(matchId, updatedMatch);
      broadcastMatchUpdate(matchId, 'match_update', updatedMatch);
    }

    return res.status(200).json(updatedMatch);
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Error ending innings/match:', err);
    return res.status(500).json({ error: 'Internal server error.' });
  } finally {
    client.release();
  }
}

export async function endMatchForce(req: Request, res: Response) {
  const { matchId } = req.params;
  try {
    await pool.query('UPDATE matches SET status = \'Completed\' WHERE id = $1', [matchId]);
    await invalidateCachedMatch(matchId);

    const updatedMatch = await getFullMatchData(matchId);
    if (updatedMatch) {
      await setCachedMatch(matchId, updatedMatch);
      broadcastMatchUpdate(matchId, 'match_update', updatedMatch);
    }

    return res.status(200).json(updatedMatch);
  } catch (err) {
    console.error('Error forcing end match:', err);
    return res.status(500).json({ error: 'Internal server error.' });
  }
}
