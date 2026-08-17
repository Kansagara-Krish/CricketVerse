import { Request, Response } from 'express';
import { prisma } from '../config/db';
import { getCachedMatch, setCachedMatch, invalidateCachedMatch } from '../config/redis';
import { broadcastNotification } from '../sockets/socketHandler';
import { spawn } from 'child_process';
import path from 'path';

// Helper to construct nested CricketMatch object from raw match row
async function getFullMatchData(matchId: string) {
  const raw = await prisma.match.findUnique({
    where: { id: matchId },
    include: {
      teamA: {
        include: {
          players: {
            include: { player: true },
          },
        },
      },
      teamB: {
        include: {
          players: {
            include: { player: true },
          },
        },
      },
      playingXIs: {
        include: { player: true },
      },
      ballRecords: {
        orderBy: { timestamp: 'asc' },
      },
    },
  });

  if (!raw) return null;

  const formatPlayer = (p: any) => ({
    id: p.id,
    name: p.name,
    role: p.role,
    nationality: p.nationality,
    runsScored: p.runsScored,
    ballsFaced: p.ballsFaced,
    wicketsTaken: p.wicketsTaken,
    runsConceded: p.runsConceded,
    oversBowled: Number(p.oversBowled),
    matchesPlayed: p.matchesPlayed,
  });

  const teamAObj = {
    id: raw.teamA.id,
    name: raw.teamA.name,
    shortName: raw.teamA.shortName,
    logoColorHex: raw.teamA.logoColorHex,
    players: raw.teamA.players.map((tp) => formatPlayer(tp.player)),
  };

  const teamBObj = {
    id: raw.teamB.id,
    name: raw.teamB.name,
    shortName: raw.teamB.shortName,
    logoColorHex: raw.teamB.logoColorHex,
    players: raw.teamB.players.map((tp) => formatPlayer(tp.player)),
  };

  const xiAPlayers = raw.playingXIs.filter((xi) => xi.teamId === raw.teamAId).map((xi) => formatPlayer(xi.player));
  const xiBPlayers = raw.playingXIs.filter((xi) => xi.teamId === raw.teamBId).map((xi) => formatPlayer(xi.player));

  const ballsList = raw.ballRecords.map((b) => ({
    run: b.run,
    extraRun: b.extraRun,
    extraType: b.extraType,
    isWicket: b.isWicket,
    wicketType: b.wicketType,
    batsmanName: b.batsmanName,
    bowlerName: b.bowlerName,
    commentary: b.commentary,
    timestamp: b.timestamp.toISOString(),
    strikerId: b.strikerId,
    nonStrikerId: b.nonStrikerId,
    bowlerId: b.bowlerId,
  }));

  return {
    id: raw.id,
    teamA: teamAObj,
    teamB: teamBObj,
    matchType: raw.matchType,
    venue: raw.venue,
    date: raw.date,
    time: raw.time,
    status: raw.status,
    tossWinner: raw.tossWinner,
    tossDecision: raw.tossDecision,
    battingTeamId: raw.battingTeamId,
    playingXI_A: xiAPlayers,
    playingXI_B: xiBPlayers,
    runsA: raw.runsA,
    wicketsA: raw.wicketsA,
    oversA: Number(raw.oversA),
    runsB: raw.runsB,
    wicketsB: raw.wicketsB,
    oversB: Number(raw.oversB),
    target: raw.target,
    scorerUsername: raw.scorerUsername,
    scorerPassword: raw.scorerPassword,
    currentStrikerId: raw.currentStrikerId,
    currentNonStrikerId: raw.currentNonStrikerId,
    currentBowlerId: raw.currentBowlerId,
    balls: ballsList,
    isFirstInnings: raw.isFirstInnings,
  };
}

export async function getMatches(req: Request, res: Response) {
  try {
    const list = await prisma.match.findMany({
      select: { id: true },
    });

    const matches: any[] = [];
    for (const row of list) {
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

  try {
    const matchId = `match_${Date.now()}`;
    await prisma.$transaction(async (tx) => {
      await tx.match.create({
        data: {
          id: matchId,
          teamAId,
          teamBId,
          matchType: matchType || 'T20',
          venue,
          date,
          time,
          status: 'Upcoming',
          scorerUsername: scorerUser,
          scorerPassword: scorerPass,
        },
      });

      // Automatically copy team players to match_playing_xi
      const teamAPlayers = await tx.teamPlayer.findMany({ where: { teamId: teamAId } });
      for (const p of teamAPlayers) {
        await tx.matchPlayingXI.create({
          data: { matchId, teamId: teamAId, playerId: p.playerId },
        });
      }

      const teamBPlayers = await tx.teamPlayer.findMany({ where: { teamId: teamBId } });
      for (const p of teamBPlayers) {
        await tx.matchPlayingXI.create({
          data: { matchId, teamId: teamBId, playerId: p.playerId },
        });
      }
    });

    try {
      const teamA = await prisma.team.findUnique({ where: { id: teamAId } });
      const teamB = await prisma.team.findUnique({ where: { id: teamBId } });
      const teamAName = teamA ? teamA.name : 'Team A';
      const teamBName = teamB ? teamB.name : 'Team B';

      broadcastNotification({
        title: 'New Match Scheduled',
        message: `${teamAName} vs ${teamBName} is scheduled on ${date} at ${time}.`,
        timestamp: new Date().toISOString()
      });
    } catch (broadcastErr) {
      console.error('Error broadcasting schedule match notification:', broadcastErr);
    }

    return res.status(201).json({ message: 'Match scheduled successfully.', id: matchId });
  } catch (err) {
    console.error('Error scheduling match:', err);
    return res.status(500).json({ error: 'Internal server error.' });
  }
}

export async function adminActivateMatch(req: Request, res: Response) {
  const { id } = req.params;
  try {
    const match = await prisma.match.findUnique({ where: { id } });
    if (!match) {
      return res.status(404).json({ error: 'Match not found.' });
    }

    if (match.status === 'Upcoming') {
      const batTeamPlayers = await prisma.teamPlayer.findMany({
        where: { teamId: match.teamAId },
        orderBy: { playerId: 'asc' },
        take: 2,
      });
      const bowlTeamPlayers = await prisma.teamPlayer.findMany({
        where: { teamId: match.teamBId },
        orderBy: { playerId: 'desc' },
        take: 1,
      });

      const strikerId = batTeamPlayers.length > 0 ? batTeamPlayers[0].playerId : '';
      const nonStrikerId = batTeamPlayers.length > 1 ? batTeamPlayers[1].playerId : '';
      const bowlerId = bowlTeamPlayers.length > 0 ? bowlTeamPlayers[0].playerId : '';

      await prisma.match.update({
        where: { id },
        data: {
          status: 'Live',
          tossWinner: match.teamAId,
          tossDecision: 'Bat',
          battingTeamId: match.teamAId,
          currentStrikerId: strikerId,
          currentNonStrikerId: nonStrikerId,
          currentBowlerId: bowlerId,
        },
      });
    } else {
      await prisma.match.update({
        where: { id },
        data: { status: 'Live' },
      });
    }

    await invalidateCachedMatch(id);
    return res.status(200).json({ message: 'Match activated to LIVE.' });
  } catch (err) {
    console.error('Error activating match:', err);
    return res.status(500).json({ error: 'Internal server error.' });
  }
}

export async function resetMatch(req: Request, res: Response) {
  const { id } = req.params;
  try {
    const match = await prisma.match.findUnique({ where: { id } });
    if (!match) {
      return res.status(404).json({ error: 'Match not found.' });
    }

    const batTeamPlayers = await prisma.teamPlayer.findMany({
      where: { teamId: match.teamAId },
      orderBy: { playerId: 'asc' },
      take: 2,
    });
    const bowlTeamPlayers = await prisma.teamPlayer.findMany({
      where: { teamId: match.teamBId },
      orderBy: { playerId: 'desc' },
      take: 1,
    });

    const strikerId = batTeamPlayers.length > 0 ? batTeamPlayers[0].playerId : '';
    const nonStrikerId = batTeamPlayers.length > 1 ? batTeamPlayers[1].playerId : '';
    const bowlerId = bowlTeamPlayers.length > 0 ? bowlTeamPlayers[0].playerId : '';

    await prisma.$transaction([
      prisma.match.update({
        where: { id },
        data: {
          runsA: 0,
          wicketsA: 0,
          oversA: 0.0,
          runsB: 0,
          wicketsB: 0,
          oversB: 0.0,
          target: 0,
          status: 'Upcoming',
          isFirstInnings: true,
          tossWinner: '',
          tossDecision: '',
          battingTeamId: '',
          currentStrikerId: strikerId,
          currentNonStrikerId: nonStrikerId,
          currentBowlerId: bowlerId,
        },
      }),
      prisma.ballRecord.deleteMany({
        where: { matchId: id },
      }),
    ]);

    await invalidateCachedMatch(id);
    return res.status(200).json({ message: 'Match reset successfully.' });
  } catch (err) {
    console.error('Error resetting match:', err);
    return res.status(500).json({ error: 'Internal server error.' });
  }
}

async function getTeamWinRate(teamId: string): Promise<number> {
  const matches = await prisma.match.findMany({
    where: {
      status: 'Completed',
      OR: [
        { teamAId: teamId },
        { teamBId: teamId }
      ]
    }
  });

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
  return 0.35 + winRate * 0.3; // map to [0.35, 0.65] range
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
    const match = await prisma.match.findUnique({ where: { id } });
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
      status: match.status
    };

    let result;
    try {
      result = await runMLPrediction(payload);
    } catch (mlErr) {
      console.warn('ML Prediction failed, falling back to rule-based prediction:', mlErr);
      
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
            const requiredRate = (runsNeeded / ballsRemaining) * 6;
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
          { name: "Current Run Rate", weight: 50 },
          { name: "Required Run Rate", weight: 50 },
          { name: "Wickets in Hand", weight: 50 },
          { name: "Powerplay Performance", weight: 50 },
          { name: "Death Overs History", weight: 50 },
          { name: "Head-to-Head Record", weight: 50 },
          { name: "Pitch Conditions", weight: 50 },
          { name: "Weather Impact", weight: 50 }
        ]
      };
    }

    return res.status(200).json(result);
  } catch (err: any) {
    console.error('Error calculating prediction:', err);
    return res.status(500).json({ error: err.message || 'Failed to calculate match prediction.' });
  }
}
