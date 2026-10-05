import { Request, Response } from 'express';
import { MatchModel } from '../models/Match';
import { TeamModel } from '../models/Team';
import { getCachedMatch, setCachedMatch, invalidateCachedMatch } from '../config/redis';
import { broadcastNotification, broadcastMatchUpdate } from '../sockets/socketHandler';
import { spawn } from 'child_process';
import path from 'path';

async function getFullMatchData(matchId: string) {
  const match = await MatchModel.findOne({ id: matchId }).lean();
  if (!match) return null;

  return {
    id: match.id,
    tournamentId: match.tournamentId,
    teamA: match.teamA,
    teamB: match.teamB,
    matchType: match.matchType,
    venue: match.venue,
    date: match.date,
    time: match.time,
    status: match.status,
    tossWinner: match.tossWinner || '',
    tossDecision: match.tossDecision || '',
    battingTeamId: match.battingTeamId || '',
    playingXI_A: match.playingXI_A || [],
    playingXI_B: match.playingXI_B || [],
    runsA: match.runsA || 0,
    wicketsA: match.wicketsA || 0,
    oversA: Number(match.oversA || 0.0),
    runsB: match.runsB || 0,
    wicketsB: match.wicketsB || 0,
    oversB: Number(match.oversB || 0.0),
    target: match.target || 0,
    scorerUsername: match.scorerUsername,
    scorerPassword: match.scorerPassword,
    currentStrikerId: match.currentStrikerId || '',
    currentNonStrikerId: match.currentNonStrikerId || '',
    currentBowlerId: match.currentBowlerId || '',
    balls: (match.balls || []).map((b: any) => ({
      run: b.run,
      extraRun: b.extraRun,
      extraType: b.extraType,
      isWicket: b.isWicket,
      wicketType: b.wicketType,
      batsmanName: b.batsmanName,
      bowlerName: b.bowlerName,
      commentary: b.commentary,
      audioUrl: b.audioUrl,
      timestamp: b.timestamp,
      strikerId: b.strikerId,
      nonStrikerId: b.nonStrikerId,
      bowlerId: b.bowlerId,
      innings: b.innings,
      battingTeamId: b.battingTeamId,
      over: b.over != null ? Number(b.over) : undefined,
    })),
    isFirstInnings: match.isFirstInnings ?? true,
    winnerTeamId: match.winnerTeamId || '',
    winnerName: match.winnerName || '',
    resultText: match.resultText || '',
  };
}

export async function getMatches(req: Request, res: Response) {
  try {
    const list = await MatchModel.find().lean();
    const formatted = list.map((match: any) => ({
      id: match.id,
      tournamentId: match.tournamentId,
      teamA: match.teamA,
      teamB: match.teamB,
      matchType: match.matchType,
      venue: match.venue,
      date: match.date,
      time: match.time,
      status: match.status,
      tossWinner: match.tossWinner || '',
      tossDecision: match.tossDecision || '',
      battingTeamId: match.battingTeamId || '',
      playingXI_A: match.playingXI_A || [],
      playingXI_B: match.playingXI_B || [],
      runsA: match.runsA || 0,
      wicketsA: match.wicketsA || 0,
      oversA: Number(match.oversA || 0.0),
      runsB: match.runsB || 0,
      wicketsB: match.wicketsB || 0,
      oversB: Number(match.oversB || 0.0),
      target: match.target || 0,
      scorerUsername: match.scorerUsername,
      scorerPassword: match.scorerPassword,
      currentStrikerId: match.currentStrikerId || '',
      currentNonStrikerId: match.currentNonStrikerId || '',
      currentBowlerId: match.currentBowlerId || '',
      balls: match.balls || [],
      isFirstInnings: match.isFirstInnings ?? true,
      winnerTeamId: match.winnerTeamId || '',
      winnerName: match.winnerName || '',
      resultText: match.resultText || '',
    }));
    return res.status(200).json(formatted);
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
  const { teamAId, teamBId, tournamentId, matchType, venue, date, time, scorerUser, scorerPass } = req.body;

  if (!teamAId || !teamBId || !venue || !date || !time || !scorerUser || !scorerPass) {
    return res.status(400).json({ error: 'All fields are required to schedule a match.' });
  }

  try {
    const teamA = await TeamModel.findOne({ id: teamAId }).lean();
    const teamB = await TeamModel.findOne({ id: teamBId }).lean();

    if (!teamA || !teamB) {
      return res.status(404).json({ error: 'Selected teams could not be found.' });
    }

    const matchId = `match_${Date.now()}`;

    const newMatch = await MatchModel.create({
      id: matchId,
      tournamentId: tournamentId || undefined,
      teamAId,
      teamBId,
      teamA,
      teamB,
      matchType: matchType || 'T20',
      venue,
      date,
      time,
      status: 'Upcoming',
      scorerUsername: scorerUser.trim(),
      scorerPassword: scorerPass,
      playingXI_A: teamA.players || [],
      playingXI_B: teamB.players || [],
      runsA: 0,
      wicketsA: 0,
      oversA: 0.0,
      runsB: 0,
      wicketsB: 0,
      oversB: 0.0,
      target: 0,
      balls: [],
      isFirstInnings: true,
    });

    try {
      broadcastNotification({
        title: 'New Match Scheduled 🏏',
        message: `${teamA.name} vs ${teamB.name} scheduled for ${date} at ${time}.`,
        timestamp: new Date().toISOString(),
      });
    } catch (broadcastErr) {
      console.error('Error broadcasting schedule match notification:', broadcastErr);
    }

    return res.status(201).json({ message: 'Match scheduled successfully.', id: matchId, match: newMatch });
  } catch (err) {
    console.error('Error scheduling match:', err);
    return res.status(500).json({ error: 'Internal server error.' });
  }
}

export async function adminActivateMatch(req: Request, res: Response) {
  const { id } = req.params;
  try {
    const match = await MatchModel.findOne({ id });
    if (!match) {
      return res.status(404).json({ error: 'Match not found.' });
    }

    if (match.status === 'Upcoming') {
      const batTeamPlayers = match.playingXI_A || [];
      const bowlTeamPlayers = match.playingXI_B || [];

      const strikerId = batTeamPlayers.length > 0 ? batTeamPlayers[0].id : '';
      const nonStrikerId = batTeamPlayers.length > 1 ? batTeamPlayers[1].id : '';
      const bowlerId = bowlTeamPlayers.length > 0 ? bowlTeamPlayers[bowlTeamPlayers.length - 1].id : '';

      match.status = 'Live';
      match.tossWinner = match.teamAId;
      match.tossDecision = 'Bat';
      match.battingTeamId = match.teamAId;
      match.currentStrikerId = strikerId;
      match.currentNonStrikerId = nonStrikerId;
      match.currentBowlerId = bowlerId;
      await match.save();
    } else {
      match.status = 'Live';
      await match.save();
    }

    await invalidateCachedMatch(id);
    const updated = await getFullMatchData(id);
    return res.status(200).json({ message: 'Match activated to LIVE.', match: updated });
  } catch (err) {
    console.error('Error activating match:', err);
    return res.status(500).json({ error: 'Internal server error.' });
  }
}

export async function resetMatch(req: Request, res: Response) {
  const { id } = req.params;
  try {
    const match = await MatchModel.findOne({ id });
    if (!match) {
      return res.status(404).json({ error: 'Match not found.' });
    }

    const batTeamPlayers = match.playingXI_A || [];
    const bowlTeamPlayers = match.playingXI_B || [];

    const strikerId = batTeamPlayers.length > 0 ? batTeamPlayers[0].id : '';
    const nonStrikerId = batTeamPlayers.length > 1 ? batTeamPlayers[1].id : '';
    const bowlerId = bowlTeamPlayers.length > 0 ? bowlTeamPlayers[bowlTeamPlayers.length - 1].id : '';

    match.runsA = 0;
    match.wicketsA = 0;
    match.oversA = 0.0;
    match.runsB = 0;
    match.wicketsB = 0;
    match.oversB = 0.0;
    match.target = 0;
    match.status = 'Upcoming';
    match.isFirstInnings = true;
    match.tossWinner = '';
    match.tossDecision = '';
    match.battingTeamId = '';
    match.currentStrikerId = strikerId;
    match.currentNonStrikerId = nonStrikerId;
    match.currentBowlerId = bowlerId;
    match.balls = [];

    // Reset all player stats within this match
    const resetPlayerStats = (arr: any[]) => {
      if (!Array.isArray(arr)) return;
      for (const p of arr) {
        p.runsScored = 0;
        p.ballsFaced = 0;
        p.wicketsTaken = 0;
        p.runsConceded = 0;
        p.oversBowled = 0;
      }
    };

    resetPlayerStats(match.playingXI_A);
    resetPlayerStats(match.playingXI_B);
    if (match.teamA && match.teamA.players) resetPlayerStats(match.teamA.players);
    if (match.teamB && match.teamB.players) resetPlayerStats(match.teamB.players);

    match.markModified('playingXI_A');
    match.markModified('playingXI_B');
    match.markModified('teamA');
    match.teamB && match.markModified('teamB');
    match.markModified('balls');

    await match.save();
    await invalidateCachedMatch(id);

    const updated = await getFullMatchData(id);
    broadcastMatchUpdate(id, 'match_update', updated);

    return res.status(200).json({ message: 'Match reset successfully.', match: updated });
  } catch (err) {
    console.error('Error resetting match:', err);
    return res.status(500).json({ error: 'Internal server error.' });
  }
}

export async function updateMatch(req: Request, res: Response) {
  const { id } = req.params;
  const { teamAId, teamBId, tournamentId, matchType, venue, date, time, scorerUser, scorerPass } = req.body;

  try {
    const existing = await MatchModel.findOne({ id });
    if (!existing) {
      return res.status(404).json({ error: 'Match not found.' });
    }

    if (teamAId && teamAId !== existing.teamAId) {
      const teamA = await TeamModel.findOne({ id: teamAId }).lean();
      if (teamA) {
        existing.teamAId = teamAId;
        existing.teamA = teamA;
        existing.playingXI_A = teamA.players || [];
      }
    }

    if (teamBId && teamBId !== existing.teamBId) {
      const teamB = await TeamModel.findOne({ id: teamBId }).lean();
      if (teamB) {
        existing.teamBId = teamBId;
        existing.teamB = teamB;
        existing.playingXI_B = teamB.players || [];
      }
    }

    if (tournamentId !== undefined) existing.tournamentId = tournamentId;
    if (matchType) existing.matchType = matchType;
    if (venue) existing.venue = venue;
    if (date) existing.date = date;
    if (time) existing.time = time;
    if (scorerUser !== undefined) existing.scorerUsername = scorerUser.trim();
    if (scorerPass !== undefined) existing.scorerPassword = scorerPass;

    await existing.save();
    await invalidateCachedMatch(id);

    const fullMatch = await getFullMatchData(id);
    return res.status(200).json({ message: 'Match updated successfully.', match: fullMatch });
  } catch (err) {
    console.error('Error updating match:', err);
    return res.status(500).json({ error: 'Internal server error.' });
  }
}

export async function deleteMatch(req: Request, res: Response) {
  const { id } = req.params;

  try {
    const existing = await MatchModel.findOneAndDelete({ id });
    if (!existing) {
      return res.status(404).json({ error: 'Match not found.' });
    }

    await invalidateCachedMatch(id);

    broadcastNotification({
      title: 'Match Removed',
      message: `Match was deleted from tournament schedule.`,
      timestamp: new Date().toISOString(),
    });

    return res.status(200).json({ message: 'Match deleted successfully.', matchId: id });
  } catch (err: any) {
    console.error('Error deleting match:', err);
    return res.status(500).json({ error: err.message || 'Internal server error.' });
  }
}

async function getTeamWinRate(teamId: string): Promise<number> {
  const matches = await MatchModel.find({
    status: 'Completed',
    $or: [{ teamAId: teamId }, { teamBId: teamId }],
  }).lean();

  if (matches.length === 0) {
    return 0.5;
  }

  let wins = 0;
  for (const m of matches) {
    if (m.runsA > m.runsB && m.teamAId === teamId) {
      wins++;
    } else if (m.runsB > m.runsA && m.teamBId === teamId) {
      wins++;
    }
  }

  const winRate = wins / matches.length;
  return 0.35 + winRate * 0.3;
}

function runMLPrediction(payload: any): Promise<any> {
  return new Promise((resolve, reject) => {
    const scriptPath = path.resolve(__dirname, '..', '..', 'ml_model', 'predict.py');
    const pythonProcess = spawn('python', [scriptPath]);

    let outputData = '';
    let errorData = '';

    pythonProcess.stdin.write(JSON.stringify(payload));
    pythonProcess.stdin.end();

    pythonProcess.stdout.on('data', (data) => {
      outputData += data.toString();
    });

    pythonProcess.stderr.on('data', (data) => {
      errorData += data.toString();
    });

    pythonProcess.on('close', (code) => {
      if (code !== 0) {
        return reject(new Error(`Python process exited with code ${code}. Error: ${errorData}`));
      }
      try {
        const parsed = JSON.parse(outputData.trim());
        if (parsed.error) {
          reject(new Error(parsed.error));
        } else {
          resolve(parsed);
        }
      } catch (err) {
        reject(new Error(`Failed to parse output JSON from python script. Output: ${outputData}`));
      }
    });
  });
}

export async function getMatchPrediction(req: Request, res: Response) {
  const { id } = req.params;
  try {
    const match = await MatchModel.findOne({ id });
    if (!match) {
      return res.status(404).json({ error: 'Match not found.' });
    }

    const teamAStrength = await getTeamWinRate(match.teamAId);
    const teamBStrength = await getTeamWinRate(match.teamBId);

    const tossWinnerIsA = match.tossWinner === match.teamAId ? 1 : 0;
    const tossDecisionBat = match.tossDecision === 'Bat' ? 1 : 0;
    const battingTeamIsA = match.battingTeamId === match.teamAId ? 1 : 0;

    const payload = {
      team_a_strength: teamAStrength,
      team_b_strength: teamBStrength,
      toss_winner_is_a: tossWinnerIsA,
      toss_decision_bat: tossDecisionBat,
      is_first_innings: match.isFirstInnings ? 1 : 0,
      batting_team_is_a: battingTeamIsA,
      runs_a: match.runsA,
      wickets_a: match.wicketsA,
      overs_a: Number(match.oversA),
      runs_b: match.runsB,
      wickets_b: match.wicketsB,
      overs_b: Number(match.oversB),
      target: match.target,
      status: match.status,
    };

    let result;
    try {
      result = await runMLPrediction(payload);
    } catch (mlErr) {
      console.warn('ML Prediction fallback:', mlErr);
      let probA = 50.0;
      if (match.status === 'Upcoming') {
        probA = 50.0;
      } else if (match.status === 'Completed') {
        probA = match.runsA > match.runsB ? 100.0 : 0.0;
      } else {
        if (match.isFirstInnings) {
          const crr = match.runsA / (Number(match.oversA) > 0 ? Number(match.oversA) : 0.1);
          probA = 50.0 + (crr - 7.5) * 5;
          if (match.wicketsA > 5) {
            probA -= (match.wicketsA - 5) * 8;
          }
        } else {
          const target = match.target;
          const currentScore = match.runsB;
          const runsNeeded = target - currentScore;
          const totalBalls = 120;
          const oversInt = Math.floor(Number(match.oversB));
          const ballsInt = Math.round((Number(match.oversB) - oversInt) * 10);
          const ballsBowled = oversInt * 6 + ballsInt;
          const ballsRemaining = totalBalls - ballsBowled;

          if (runsNeeded <= 0) {
            probA = 0.0;
          } else if (ballsRemaining <= 0 || match.wicketsB >= 10) {
            probA = 100.0;
          } else {
            const requiredRate = (runsNeeded / (ballsRemaining || 1)) * 6;
            const probB = 50.0 - (requiredRate - 7.5) * 7 + (10 - match.wicketsB) * 3;
            probA = 100.0 - probB;
          }
        }
      }

      probA = Math.max(1.0, Math.min(99.0, probA));
      const probB = 100.0 - probA;

      result = {
        winProbabilityA: Number(probA.toFixed(1)),
        winProbabilityB: Number(probB.toFixed(1)),
        factors: [
          { name: 'Current Run Rate', weight: 50 },
          { name: 'Required Run Rate', weight: 50 },
          { name: 'Wickets in Hand', weight: 50 },
          { name: 'Powerplay Performance', weight: 50 },
          { name: 'Death Overs History', weight: 50 },
          { name: 'Head-to-Head Record', weight: 50 },
          { name: 'Pitch Conditions', weight: 50 },
          { name: 'Weather Impact', weight: 50 },
        ],
      };
    }

    return res.status(200).json(result);
  } catch (err: any) {
    console.error('Error calculating prediction:', err);
    return res.status(500).json({ error: err.message || 'Failed to calculate match prediction.' });
  }
}
