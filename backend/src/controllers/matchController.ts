import { Request, Response } from 'express';
import { prisma } from '../config/db';
import { getCachedMatch, setCachedMatch, invalidateCachedMatch } from '../config/redis';
import { broadcastNotification } from '../sockets/socketHandler';

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
