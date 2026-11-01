import { Request, Response } from 'express';
import { TeamModel } from '../models/Team';
import { MatchModel } from '../models/Match';
import { redis, invalidateCachedMatch } from '../config/redis';
import { broadcastMatchUpdate, broadcastTeamUpdate, broadcastNotification } from '../sockets/socketHandler';

export async function getTeams(req: Request, res: Response) {
  try {
    const teams = await TeamModel.find().lean();
    const matches = await MatchModel.find().lean();

    // Map of aggregated player stats from matches
    const statsMap: Record<string, { runsScored: number; ballsFaced: number; wicketsTaken: number; runsConceded: number; legalBallsBowled: number; matchesPlayed: number }> = {};

    matches.forEach((m: any) => {
      const matchPlayerIds = new Set<string>();

      const processPlayerList = (list: any[]) => {
        if (!Array.isArray(list)) return;
        list.forEach((p: any) => {
          if (!p || !p.id) return;
          matchPlayerIds.add(p.id);
          if (!statsMap[p.id]) {
            statsMap[p.id] = { runsScored: 0, ballsFaced: 0, wicketsTaken: 0, runsConceded: 0, legalBallsBowled: 0, matchesPlayed: 0 };
          }
          statsMap[p.id].runsScored += Number(p.runsScored || 0);
          statsMap[p.id].ballsFaced += Number(p.ballsFaced || 0);
          statsMap[p.id].wicketsTaken += Number(p.wicketsTaken || 0);
          statsMap[p.id].runsConceded += Number(p.runsConceded || 0);
          const overs = Number(p.oversBowled || 0);
          const balls = Math.floor(overs) * 6 + Math.round((overs - Math.floor(overs)) * 10);
          statsMap[p.id].legalBallsBowled += balls;
        });
      };

      processPlayerList(m.playingXI_A);
      processPlayerList(m.playingXI_B);

      matchPlayerIds.forEach((pId) => {
        if (statsMap[pId]) statsMap[pId].matchesPlayed += 1;
      });
    });

    const formatted = teams.map((t: any) => ({
      id: t.id,
      name: t.name,
      shortName: t.shortName,
      logoColorHex: t.logoColorHex,
      players: (t.players || []).map((p: any) => {
        const agg = statsMap[p.id];
        const baseOvers = Number(p.oversBowled || 0);
        const baseLegalBalls = Math.floor(baseOvers) * 6 + Math.round((baseOvers - Math.floor(baseOvers)) * 10);
        const totalLegalBalls = baseLegalBalls + (agg ? agg.legalBallsBowled : 0);
        const totalOversFormatted = parseFloat((Math.floor(totalLegalBalls / 6) + (totalLegalBalls % 6) / 10).toFixed(1));

        return {
          id: p.id,
          name: p.name,
          role: p.role,
          nationality: p.nationality || 'IND',
          isCaptain: p.isCaptain ?? false,
          isViceCaptain: p.isViceCaptain ?? false,
          runsScored: (p.runsScored || 0) + (agg ? agg.runsScored : 0),
          ballsFaced: (p.ballsFaced || 0) + (agg ? agg.ballsFaced : 0),
          wicketsTaken: (p.wicketsTaken || 0) + (agg ? agg.wicketsTaken : 0),
          runsConceded: (p.runsConceded || 0) + (agg ? agg.runsConceded : 0),
          oversBowled: totalOversFormatted,
          matchesPlayed: Math.max(p.matchesPlayed || 0, agg ? agg.matchesPlayed : 0),
        };
      }),
    }));

    return res.status(200).json(formatted);
  } catch (err) {
    console.error('Error fetching teams:', err);
    return res.status(500).json({ error: 'Internal server error.' });
  }
}

export async function getTeamById(req: Request, res: Response) {
  const { id } = req.params;
  try {
    const team = await TeamModel.findOne({ id }).lean();
    if (!team) {
      return res.status(404).json({ error: 'Team not found.' });
    }

    const matches = await MatchModel.find().lean();
    const statsMap: Record<string, { runsScored: number; ballsFaced: number; wicketsTaken: number; runsConceded: number; legalBallsBowled: number; matchesPlayed: number }> = {};

    matches.forEach((m: any) => {
      const matchPlayerIds = new Set<string>();
      const processPlayerList = (list: any[]) => {
        if (!Array.isArray(list)) return;
        list.forEach((p: any) => {
          if (!p || !p.id) return;
          matchPlayerIds.add(p.id);
          if (!statsMap[p.id]) {
            statsMap[p.id] = { runsScored: 0, ballsFaced: 0, wicketsTaken: 0, runsConceded: 0, legalBallsBowled: 0, matchesPlayed: 0 };
          }
          statsMap[p.id].runsScored += Number(p.runsScored || 0);
          statsMap[p.id].ballsFaced += Number(p.ballsFaced || 0);
          statsMap[p.id].wicketsTaken += Number(p.wicketsTaken || 0);
          statsMap[p.id].runsConceded += Number(p.runsConceded || 0);
          const overs = Number(p.oversBowled || 0);
          const balls = Math.floor(overs) * 6 + Math.round((overs - Math.floor(overs)) * 10);
          statsMap[p.id].legalBallsBowled += balls;
        });
      };
      processPlayerList(m.playingXI_A);
      processPlayerList(m.playingXI_B);
      matchPlayerIds.forEach((pId) => {
        if (statsMap[pId]) statsMap[pId].matchesPlayed += 1;
      });
    });

    const formattedTeam = {
      ...team,
      players: (team.players || []).map((p: any) => {
        const agg = statsMap[p.id];
        const baseOvers = Number(p.oversBowled || 0);
        const baseLegalBalls = Math.floor(baseOvers) * 6 + Math.round((baseOvers - Math.floor(baseOvers)) * 10);
        const totalLegalBalls = baseLegalBalls + (agg ? agg.legalBallsBowled : 0);
        const totalOversFormatted = parseFloat((Math.floor(totalLegalBalls / 6) + (totalLegalBalls % 6) / 10).toFixed(1));

        return {
          ...p,
          runsScored: (p.runsScored || 0) + (agg ? agg.runsScored : 0),
          ballsFaced: (p.ballsFaced || 0) + (agg ? agg.ballsFaced : 0),
          wicketsTaken: (p.wicketsTaken || 0) + (agg ? agg.wicketsTaken : 0),
          runsConceded: (p.runsConceded || 0) + (agg ? agg.runsConceded : 0),
          oversBowled: totalOversFormatted,
          matchesPlayed: Math.max(p.matchesPlayed || 0, agg ? agg.matchesPlayed : 0),
        };
      }),
    };

    return res.status(200).json(formattedTeam);
  } catch (err) {
    console.error('Error fetching team by id:', err);
    return res.status(500).json({ error: 'Internal server error.' });
  }
}

export async function addTeam(req: Request, res: Response) {
  const { name, shortName, logoColorHex, players } = req.body;
  if (!name || !shortName) {
    return res.status(400).json({ error: 'Name and short name are required.' });
  }

  try {
    const teamId = name.toLowerCase().trim().replace(/[^a-z0-9]/g, '_') + '_' + Date.now();

    const formattedPlayers = (Array.isArray(players) ? players : []).map((p: any, idx: number) => ({
      id: p.id || `${teamId}_p${idx + 1}`,
      name: p.name || `Player ${idx + 1}`,
      role: p.role || 'Batter',
      nationality: p.nationality || 'IND',
      isCaptain: Boolean(p.isCaptain),
      isViceCaptain: Boolean(p.isViceCaptain),
      runsScored: p.runsScored || 0,
      ballsFaced: p.ballsFaced || 0,
      wicketsTaken: p.wicketsTaken || 0,
      runsConceded: p.runsConceded || 0,
      oversBowled: p.oversBowled || 0.0,
      matchesPlayed: p.matchesPlayed || 0,
    }));

    const newTeam = await TeamModel.create({
      id: teamId,
      name: name.trim(),
      shortName: shortName.trim().toUpperCase(),
      logoColorHex: logoColorHex || '0xFF028A6B',
      players: formattedPlayers,
    });

    if (redis) {
      await redis.del('teams:all');
    }

    return res.status(201).json({ message: 'Team created successfully.', id: teamId, team: newTeam });
  } catch (err) {
    console.error('Error adding team:', err);
    return res.status(500).json({ error: 'Internal server error.' });
  }
}

export async function updateTeam(req: Request, res: Response) {
  const { id } = req.params;
  const { name, shortName, logoColorHex, players } = req.body;

  try {
    const updateData: any = {};
    if (name !== undefined) updateData.name = name.trim();
    if (shortName !== undefined) updateData.shortName = shortName.trim().toUpperCase();
    if (logoColorHex !== undefined) updateData.logoColorHex = logoColorHex;
    if (players !== undefined && Array.isArray(players)) updateData.players = players;

    const updated = await TeamModel.findOneAndUpdate(
      { id },
      { $set: updateData },
      { new: true }
    );

    if (!updated) {
      return res.status(404).json({ error: 'Team not found.' });
    }

    if (redis) {
      await redis.del('teams:all');
    }

    await syncTeamPlayersToMatches(updated);
    broadcastTeamUpdate('team_update', updated.toJSON ? updated.toJSON() : updated);

    return res.status(200).json({ message: 'Team updated successfully.', team: updated });
  } catch (err) {
    console.error('Error updating team:', err);
    return res.status(500).json({ error: 'Internal server error.' });
  }
}

export async function deleteTeam(req: Request, res: Response) {
  const { id } = req.params;
  try {
    const deleted = await TeamModel.findOneAndDelete({ id });
    if (!deleted) {
      return res.status(404).json({ error: 'Team not found.' });
    }

    if (redis) {
      await redis.del('teams:all');
    }

    broadcastTeamUpdate('team_deleted', { id });

    return res.status(200).json({ message: 'Team deleted successfully.' });
  } catch (err) {
    console.error('Error deleting team:', err);
    return res.status(500).json({ error: 'Internal server error.' });
  }
}

function formatMatchPayload(match: any) {
  return {
    id: match.id,
    tournamentId: match.tournamentId,
    teamA: match.teamA,
    teamB: match.teamB,
    matchType: match.matchType || 'T20',
    venue: match.venue || '',
    date: match.date || '',
    time: match.time || '',
    status: match.status || 'Upcoming',
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
      run: b.run ?? 0,
      extraRun: b.extraRun ?? 0,
      extraType: b.extraType ?? 'None',
      isWicket: Boolean(b.isWicket),
      wicketType: b.wicketType ?? 'None',
      batsmanName: b.batsmanName ?? '',
      bowlerName: b.bowlerName ?? '',
      commentary: b.commentary ?? '',
      audioUrl: b.audioUrl,
      timestamp: b.timestamp || new Date().toISOString(),
      strikerId: b.strikerId,
      nonStrikerId: b.nonStrikerId,
      bowlerId: b.bowlerId,
      innings: b.innings ?? 1,
      battingTeamId: b.battingTeamId,
      over: b.over != null ? Number(b.over) : undefined,
    })),
    isFirstInnings: match.isFirstInnings ?? true,
    winnerTeamId: match.winnerTeamId || '',
    winnerName: match.winnerName || '',
    resultText: match.resultText || '',
  };
}

async function syncTeamPlayersToMatches(team: any) {
  try {
    const teamId = team.id;
    const teamData = team.toJSON ? team.toJSON() : team;

    // Find all matches featuring this team across all matches and tournaments
    const matches = await MatchModel.find({
      $or: [
        { teamAId: teamId },
        { 'teamA.id': teamId },
        { teamBId: teamId },
        { 'teamB.id': teamId },
      ],
    });

    const playerMap = new Map<string, any>((teamData.players || []).map((p: any) => [p.id, p]));

    for (const match of matches) {
      let changed = false;

      // Update Team A
      if (match.teamA?.id === teamId || match.teamAId === teamId) {
        match.teamA = teamData;
        const currentXI = Array.isArray(match.playingXI_A) ? match.playingXI_A : [];
        const existingMap = new Map<string, any>(currentXI.map((p: any) => [p.id, p]));

        const updatedXI = teamData.players.map((tp: any) => {
          const rawEx = existingMap.get(tp.id);
          const ex: any = rawEx?.toObject ? rawEx.toObject() : rawEx;
          return ex
            ? {
                ...tp,
                runsScored: ex.runsScored ?? tp.runsScored ?? 0,
                ballsFaced: ex.ballsFaced ?? tp.ballsFaced ?? 0,
                isOut: ex.isOut ?? tp.isOut ?? false,
                dismissalInfo: ex.dismissalInfo ?? tp.dismissalInfo ?? '',
                oversBowled: ex.oversBowled ?? tp.oversBowled ?? 0.0,
                wicketsTaken: ex.wicketsTaken ?? tp.wicketsTaken ?? 0,
                runsConceded: ex.runsConceded ?? tp.runsConceded ?? 0,
              }
            : tp;
        });

        // Retain any player who participated in this match even if removed from general squad
        for (const [pId, rawEx] of existingMap.entries()) {
          if (!playerMap.has(pId)) {
            const ex: any = rawEx?.toObject ? rawEx.toObject() : rawEx;
            const hasParticipated = (ex.runsScored && ex.runsScored > 0) ||
                                    (ex.ballsFaced && ex.ballsFaced > 0) ||
                                    (ex.oversBowled && ex.oversBowled > 0) ||
                                    ex.isOut;
            if (hasParticipated) {
              updatedXI.push(ex);
            }
          }
        }

        match.playingXI_A = updatedXI;

        // Ensure active striker/non-striker/bowler fallback if removed from active playing list
        const activeIdsA = new Set(updatedXI.map((p: any) => p.id));
        if (match.battingTeamId === match.teamA.id || match.battingTeamId === match.teamAId) {
          if (match.currentStrikerId && !activeIdsA.has(match.currentStrikerId) && updatedXI.length > 0) {
            match.currentStrikerId = updatedXI[0].id;
          }
          if (match.currentNonStrikerId && !activeIdsA.has(match.currentNonStrikerId)) {
            match.currentNonStrikerId = updatedXI.length > 1 ? updatedXI[1].id : (updatedXI[0]?.id || '');
          }
        } else {
          if (match.currentBowlerId && !activeIdsA.has(match.currentBowlerId) && updatedXI.length > 0) {
            match.currentBowlerId = updatedXI[updatedXI.length - 1].id;
          }
        }

        match.markModified('teamA');
        match.markModified('playingXI_A');
        changed = true;
      }

      // Update Team B
      if (match.teamB?.id === teamId || match.teamBId === teamId) {
        match.teamB = teamData;
        const currentXI = Array.isArray(match.playingXI_B) ? match.playingXI_B : [];
        const existingMap = new Map<string, any>(currentXI.map((p: any) => [p.id, p]));

        const updatedXI = teamData.players.map((tp: any) => {
          const rawEx = existingMap.get(tp.id);
          const ex: any = rawEx?.toObject ? rawEx.toObject() : rawEx;
          return ex
            ? {
                ...tp,
                runsScored: ex.runsScored ?? tp.runsScored ?? 0,
                ballsFaced: ex.ballsFaced ?? tp.ballsFaced ?? 0,
                isOut: ex.isOut ?? tp.isOut ?? false,
                dismissalInfo: ex.dismissalInfo ?? tp.dismissalInfo ?? '',
                oversBowled: ex.oversBowled ?? tp.oversBowled ?? 0.0,
                wicketsTaken: ex.wicketsTaken ?? tp.wicketsTaken ?? 0,
                runsConceded: ex.runsConceded ?? tp.runsConceded ?? 0,
              }
            : tp;
        });

        // Retain any player who participated in this match even if removed from general squad
        for (const [pId, rawEx] of existingMap.entries()) {
          if (!playerMap.has(pId)) {
            const ex: any = rawEx?.toObject ? rawEx.toObject() : rawEx;
            const hasParticipated = (ex.runsScored && ex.runsScored > 0) ||
                                    (ex.ballsFaced && ex.ballsFaced > 0) ||
                                    (ex.oversBowled && ex.oversBowled > 0) ||
                                    ex.isOut;
            if (hasParticipated) {
              updatedXI.push(ex);
            }
          }
        }

        match.playingXI_B = updatedXI;

        // Ensure active striker/non-striker/bowler fallback if removed from active playing list
        const activeIdsB = new Set(updatedXI.map((p: any) => p.id));
        if (match.battingTeamId === match.teamB.id || match.battingTeamId === match.teamBId) {
          if (match.currentStrikerId && !activeIdsB.has(match.currentStrikerId) && updatedXI.length > 0) {
            match.currentStrikerId = updatedXI[0].id;
          }
          if (match.currentNonStrikerId && !activeIdsB.has(match.currentNonStrikerId)) {
            match.currentNonStrikerId = updatedXI.length > 1 ? updatedXI[1].id : (updatedXI[0]?.id || '');
          }
        } else {
          if (match.currentBowlerId && !activeIdsB.has(match.currentBowlerId) && updatedXI.length > 0) {
            match.currentBowlerId = updatedXI[updatedXI.length - 1].id;
          }
        }

        match.markModified('teamB');
        match.markModified('playingXI_B');
        changed = true;
      }

      // Live update player names across ball records
      if (Array.isArray(match.balls)) {
        for (const ball of match.balls) {
          if (ball.strikerId && playerMap.has(ball.strikerId)) {
            ball.batsmanName = playerMap.get(ball.strikerId).name;
          }
          if (ball.bowlerId && playerMap.has(ball.bowlerId)) {
            ball.bowlerName = playerMap.get(ball.bowlerId).name;
          }
        }
        match.markModified('balls');
      }

      if (changed) {
        await match.save();
        await invalidateCachedMatch(match.id);
        const payload = formatMatchPayload(match);
        // Broadcast match update so managers, scorers, and viewers get updated squad instantly
        broadcastMatchUpdate(match.id, 'match_update', payload);
      }
    }
  } catch (err) {
    console.error('Error syncing team players to matches:', err);
  }
}

export async function addPlayer(req: Request, res: Response) {
  const { teamId } = req.params;
  const { id, name, role, nationality, isCaptain, isViceCaptain } = req.body;

  if (!name || !role) {
    return res.status(400).json({ error: 'Player name and role are required.' });
  }

  if (isCaptain && isViceCaptain) {
    return res.status(400).json({ error: 'A player cannot simultaneously be assigned as both Captain and Vice-Captain.' });
  }

  try {
    const team = await TeamModel.findOne({ id: teamId });
    if (!team) {
      return res.status(404).json({ error: 'Team not found.' });
    }

    const playerId = id || `${teamId}_p_${Date.now()}`;

    // If new player is captain or vice-captain, demote existing ones
    if (isCaptain) {
      team.players.forEach((p: any) => {
        if (p.isCaptain) p.isCaptain = false;
      });
    }
    if (isViceCaptain) {
      team.players.forEach((p: any) => {
        if (p.isViceCaptain) p.isViceCaptain = false;
      });
    }

    const newPlayerData = {
      id: playerId,
      name: name.trim(),
      role: role.trim(),
      nationality: nationality || 'IND',
      isCaptain: Boolean(isCaptain),
      isViceCaptain: Boolean(isViceCaptain),
      runsScored: 0,
      ballsFaced: 0,
      wicketsTaken: 0,
      runsConceded: 0,
      oversBowled: 0.0,
      matchesPlayed: 0,
    };

    team.players.push(newPlayerData);

    await team.save();

    if (redis) {
      await redis.del('teams:all');
    }

    // Live sync to matches & broadcast real-time socket events
    await syncTeamPlayersToMatches(team);
    broadcastTeamUpdate('team_update', team.toJSON());
    broadcastNotification({
      title: 'New Player Added',
      message: `${name.trim()} was added to ${team.name} as ${role.trim()}.`,
    });

    return res.status(201).json({ message: 'Player added to team successfully.', playerId });
  } catch (err) {
    console.error('Error adding player:', err);
    return res.status(500).json({ error: 'Internal server error.' });
  }
}

export async function updatePlayer(req: Request, res: Response) {
  const { id } = req.params;
  const { name, role, nationality, isCaptain, isViceCaptain, runsScored, ballsFaced, wicketsTaken, runsConceded, oversBowled, matchesPlayed } = req.body;

  if (isCaptain && isViceCaptain) {
    return res.status(400).json({ error: 'A player cannot simultaneously be assigned as both Captain and Vice-Captain.' });
  }

  try {
    const team = await TeamModel.findOne({ 'players.id': id });
    if (!team) {
      return res.status(404).json({ error: 'Player or team not found.' });
    }

    const player = team.players.find((p: any) => p.id === id);
    if (!player) {
      return res.status(404).json({ error: 'Player not found in team.' });
    }

    if (isCaptain) {
      team.players.forEach((p: any) => {
        if (p.id !== id && p.isCaptain) p.isCaptain = false;
      });
    }
    if (isViceCaptain) {
      team.players.forEach((p: any) => {
        if (p.id !== id && p.isViceCaptain) p.isViceCaptain = false;
      });
    }

    if (name !== undefined) player.name = name.trim();
    if (role !== undefined) player.role = role.trim();
    if (nationality !== undefined) player.nationality = nationality;
    if (isCaptain !== undefined) player.isCaptain = Boolean(isCaptain);
    if (isViceCaptain !== undefined) player.isViceCaptain = Boolean(isViceCaptain);
    if (runsScored !== undefined) player.runsScored = runsScored;
    if (ballsFaced !== undefined) player.ballsFaced = ballsFaced;
    if (wicketsTaken !== undefined) player.wicketsTaken = wicketsTaken;
    if (runsConceded !== undefined) player.runsConceded = runsConceded;
    if (oversBowled !== undefined) player.oversBowled = Number(oversBowled);
    if (matchesPlayed !== undefined) player.matchesPlayed = matchesPlayed;

    team.markModified('players');
    await team.save();

    if (redis) {
      await redis.del('teams:all');
    }

    // Live sync to matches & broadcast real-time socket events
    await syncTeamPlayersToMatches(team);
    broadcastTeamUpdate('team_update', team.toJSON());
    broadcastNotification({
      title: 'Player Updated',
      message: `${player.name} (${team.name}) details updated live.`,
    });

    return res.status(200).json({ message: 'Player updated successfully.' });
  } catch (err) {
    console.error('Error updating player:', err);
    return res.status(500).json({ error: 'Internal server error.' });
  }
}

export async function removePlayer(req: Request, res: Response) {
  const { playerId } = req.params;

  try {
    const team = await TeamModel.findOne({ 'players.id': playerId });
    if (!team) {
      return res.status(404).json({ error: 'Player not found.' });
    }

    // Safety Validation: Check if player is currently actively batting or bowling in any live match
    const activeLiveMatch = await MatchModel.findOne({
      status: 'Live',
      $or: [
        { currentStrikerId: playerId },
        { currentNonStrikerId: playerId },
        { currentBowlerId: playerId },
      ],
    });

    if (activeLiveMatch) {
      const activePlayer = team.players.find((p: any) => p.id === playerId);
      const pName = activePlayer?.name || 'This player';
      return res.status(400).json({
        error: `Cannot delete ${pName} because they are actively batting or bowling in an ongoing Live match. Please change the active batsman/bowler in the Manager panel first.`,
      });
    }

    team.players = team.players.filter((p: any) => p.id !== playerId);
    team.markModified('players');
    await team.save();

    if (redis) {
      await redis.del('teams:all');
    }

    // Live sync to matches & broadcast real-time socket events
    await syncTeamPlayersToMatches(team);
    broadcastTeamUpdate('team_update', team.toJSON());
    broadcastNotification({
      title: 'Player Removed',
      message: `A player was removed from ${team.name}.`,
    });

    return res.status(200).json({ message: 'Player removed successfully.' });
  } catch (err) {
    console.error('Error removing player:', err);
    return res.status(500).json({ error: 'Internal server error.' });
  }
}
