import { Request, Response } from 'express';
import { prisma } from '../config/db';
import { redis } from '../config/redis';

// Helper to fetch all teams with their players
async function fetchTeamsWithPlayersFromDB() {
  const teams = await prisma.team.findMany({
    include: {
      players: {
        include: {
          player: true,
        },
      },
    },
  });

  return teams.map((team) => ({
    id: team.id,
    name: team.name,
    shortName: team.shortName,
    logoColorHex: team.logoColorHex,
    players: team.players.map((tp) => ({
      id: tp.player.id,
      name: tp.player.name,
      role: tp.player.role,
      nationality: tp.player.nationality,
      runsScored: tp.player.runsScored,
      ballsFaced: tp.player.ballsFaced,
      wicketsTaken: tp.player.wicketsTaken,
      runsConceded: tp.player.runsConceded,
      oversBowled: Number(tp.player.oversBowled),
      matchesPlayed: tp.player.matchesPlayed,
    })),
  }));
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

  try {
    const teamId = name.toLowerCase().replaceAll(' ', '_');

    await prisma.$transaction(async (tx) => {
      await tx.team.create({
        data: {
          id: teamId,
          name,
          shortName,
          logoColorHex,
        },
      });

      if (Array.isArray(players)) {
        for (const p of players) {
          await tx.player.create({
            data: {
              id: p.id,
              name: p.name,
              role: p.role,
              nationality: p.nationality || 'IND',
              runsScored: p.runsScored || 0,
              ballsFaced: p.ballsFaced || 0,
              wicketsTaken: p.wicketsTaken || 0,
              runsConceded: p.runsConceded || 0,
              oversBowled: p.oversBowled || 0.0,
              matchesPlayed: p.matchesPlayed || 0,
              teams: {
                create: {
                  teamId,
                },
              },
            },
          });
        }
      }
    });

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
    console.error('Error adding team:', err);
    return res.status(500).json({ error: 'Internal server error.' });
  }
}

export async function updateTeam(req: Request, res: Response) {
  const { id } = req.params;
  const { name, shortName, logoColorHex } = req.body;

  try {
    await prisma.team.update({
      where: { id },
      data: {
        name,
        shortName,
        logoColorHex,
      },
    });

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
    await prisma.team.delete({ where: { id } });

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

  try {
    await prisma.player.create({
      data: {
        id,
        name,
        role,
        nationality: nationality || 'IND',
        runsScored: 0,
        ballsFaced: 0,
        wicketsTaken: 0,
        runsConceded: 0,
        oversBowled: 0.0,
        matchesPlayed: 0,
        teams: {
          create: {
            teamId,
          },
        },
      },
    });

    // Invalidate Redis cache
    if (redis) {
      await redis.del('teams:all');
    }

    return res.status(201).json({ message: 'Player added to team successfully.' });
  } catch (err) {
    console.error('Error adding player:', err);
    return res.status(500).json({ error: 'Internal server error.' });
  }
}

export async function updatePlayer(req: Request, res: Response) {
  const { id } = req.params;
  const { name, role, nationality, runsScored, ballsFaced, wicketsTaken, runsConceded, oversBowled, matchesPlayed } = req.body;

  try {
    await prisma.player.update({
      where: { id },
      data: {
        name,
        role,
        nationality,
        runsScored,
        ballsFaced,
        wicketsTaken,
        runsConceded,
        oversBowled,
        matchesPlayed,
      },
    });

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
    await prisma.player.delete({ where: { id: playerId } });

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
