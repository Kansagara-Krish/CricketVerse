import { Request, Response } from 'express';
import { TeamModel } from '../models/Team';
import { MatchModel } from '../models/Match';
import { redis } from '../config/redis';

export async function getTeams(req: Request, res: Response) {
  try {
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

    const teams = await TeamModel.find().lean();
    const formatted = teams.map((t: any) => ({
      id: t.id,
      name: t.name,
      shortName: t.shortName,
      logoColorHex: t.logoColorHex,
      players: (t.players || []).map((p: any) => ({
        id: p.id,
        name: p.name,
        role: p.role,
        nationality: p.nationality || 'IND',
        isCaptain: p.isCaptain ?? false,
        isViceCaptain: p.isViceCaptain ?? false,
        runsScored: p.runsScored ?? 0,
        ballsFaced: p.ballsFaced ?? 0,
        wicketsTaken: p.wicketsTaken ?? 0,
        runsConceded: p.runsConceded ?? 0,
        oversBowled: Number(p.oversBowled ?? 0),
        matchesPlayed: p.matchesPlayed ?? 0,
      })),
    }));

    if (redis) {
      await redis.set('teams:all', JSON.stringify(formatted), 'EX', 86400);
    }

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
    return res.status(200).json(team);
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

    return res.status(200).json({ message: 'Team deleted successfully.' });
  } catch (err) {
    console.error('Error deleting team:', err);
    return res.status(500).json({ error: 'Internal server error.' });
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

    team.players.push({
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
    });

    await team.save();

    if (redis) {
      await redis.del('teams:all');
    }

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

    team.players = team.players.filter((p: any) => p.id !== playerId);
    team.markModified('players');
    await team.save();

    if (redis) {
      await redis.del('teams:all');
    }

    return res.status(200).json({ message: 'Player removed successfully.' });
  } catch (err) {
    console.error('Error removing player:', err);
    return res.status(500).json({ error: 'Internal server error.' });
  }
}
