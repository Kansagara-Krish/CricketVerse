import { Request, Response } from 'express';
import { TournamentModel } from '../models/Tournament';
import { MatchModel } from '../models/Match';
import { TeamModel } from '../models/Team';
import { broadcastNotification } from '../sockets/socketHandler';

function parseOversToDecimal(oversVal: number): number {
  if (!oversVal || oversVal <= 0) return 0;
  const completedOvers = Math.floor(oversVal);
  const balls = Math.round((oversVal - completedOvers) * 10);
  return completedOvers + (balls / 6.0);
}

export async function getTournaments(req: Request, res: Response) {
  try {
    const tournaments = await TournamentModel.find().sort({ createdAt: -1 }).lean();

    // Dynamically update real matches and teams counts from database
    const populated = await Promise.all(
      tournaments.map(async (t: any) => {
        const actualMatchCount = await MatchModel.countDocuments({ tournamentId: t.id });
        const teamsCount = t.participatingTeamIds?.length || t.teamsCount || 0;
        return {
          ...t,
          matchesCount: actualMatchCount > 0 ? actualMatchCount : t.matchesCount,
          teamsCount,
        };
      })
    );

    return res.status(200).json(populated);
  } catch (err) {
    console.error('Error fetching tournaments:', err);
    return res.status(500).json({ error: 'Internal server error.' });
  }
}

export async function getTournamentById(req: Request, res: Response) {
  const { id } = req.params;
  try {
    const tournament = await TournamentModel.findOne({ id }).lean();
    if (!tournament) {
      return res.status(404).json({ error: 'Tournament not found.' });
    }

    const actualMatchCount = await MatchModel.countDocuments({ tournamentId: id });
    const formatted = {
      ...tournament,
      matchesCount: actualMatchCount > 0 ? actualMatchCount : tournament.matchesCount,
    };

    return res.status(200).json(formatted);
  } catch (err) {
    console.error('Error fetching tournament by id:', err);
    return res.status(500).json({ error: 'Internal server error.' });
  }
}

export async function getTournamentStandings(req: Request, res: Response) {
  const { id } = req.params;
  try {
    const tournament = await TournamentModel.findOne({ id }).lean();
    if (!tournament) {
      return res.status(404).json({ error: 'Tournament not found.' });
    }

    // Find all teams or participating teams
    let teamsQuery: any = {};
    if (tournament.participatingTeamIds && tournament.participatingTeamIds.length > 0) {
      teamsQuery = { id: { $in: tournament.participatingTeamIds } };
    }
    let teams = await TeamModel.find(teamsQuery).lean();
    if (teams.length === 0) {
      teams = await TeamModel.find().limit(8).lean();
    }

    // Find all matches for this tournament
    const matches = await MatchModel.find({ tournamentId: id }).lean();

    // Map each team to their calculated standings
    const standingsMap = new Map<string, any>();
    for (const team of teams) {
      standingsMap.set(team.id, {
        teamId: team.id,
        teamName: team.name,
        shortName: team.shortName,
        logoColorHex: team.logoColorHex || '0xFF028A6B',
        played: 0,
        won: 0,
        lost: 0,
        tied: 0,
        points: 0,
        runsScored: 0,
        oversFacedDecimal: 0,
        runsConceded: 0,
        oversBowledDecimal: 0,
        nrr: '+0.00',
        nrrValue: 0.0,
      });
    }

    for (const m of matches) {
      const teamAEntry = standingsMap.get(m.teamAId);
      const teamBEntry = standingsMap.get(m.teamBId);

      const isCompleted = m.status === 'Completed';

      // Aggregate runs & overs if match has started
      if (m.status === 'Live' || m.status === 'Completed') {
        const decOversA = parseOversToDecimal(Number(m.oversA || 0));
        const decOversB = parseOversToDecimal(Number(m.oversB || 0));

        if (teamAEntry) {
          teamAEntry.runsScored += Number(m.runsA || 0);
          teamAEntry.oversFacedDecimal += decOversA;
          teamAEntry.runsConceded += Number(m.runsB || 0);
          teamAEntry.oversBowledDecimal += decOversB;
        }

        if (teamBEntry) {
          teamBEntry.runsScored += Number(m.runsB || 0);
          teamBEntry.oversFacedDecimal += decOversB;
          teamBEntry.runsConceded += Number(m.runsA || 0);
          teamBEntry.oversBowledDecimal += decOversA;
        }
      }

      if (isCompleted) {
        if (teamAEntry) teamAEntry.played += 1;
        if (teamBEntry) teamBEntry.played += 1;

        if (m.winnerTeamId === m.teamAId) {
          if (teamAEntry) teamAEntry.won += 1;
          if (teamBEntry) teamBEntry.lost += 1;
        } else if (m.winnerTeamId === m.teamBId) {
          if (teamBEntry) teamBEntry.won += 1;
          if (teamAEntry) teamAEntry.lost += 1;
        } else if (m.winnerName === 'Tie' || m.runsA === m.runsB) {
          if (teamAEntry) teamAEntry.tied += 1;
          if (teamBEntry) teamBEntry.tied += 1;
        }
      }
    }

    const standings = Array.from(standingsMap.values()).map((s) => {
      s.points = (s.won * 2) + (s.tied * 1);
      const forRate = s.oversFacedDecimal > 0 ? (s.runsScored / s.oversFacedDecimal) : 0;
      const againstRate = s.oversBowledDecimal > 0 ? (s.runsConceded / s.oversBowledDecimal) : 0;
      const nrrVal = forRate - againstRate;
      s.nrrValue = nrrVal;
      s.nrr = (nrrVal >= 0 ? `+${nrrVal.toFixed(2)}` : nrrVal.toFixed(2));
      return s;
    });

    // Sort by Points (desc), NRR (desc), Won (desc), Name (asc)
    standings.sort((a, b) => {
      if (b.points !== a.points) return b.points - a.points;
      if (b.nrrValue !== a.nrrValue) return b.nrrValue - a.nrrValue;
      if (b.won !== a.won) return b.won - a.won;
      return a.teamName.localeCompare(b.teamName);
    });

    return res.status(200).json({
      tournament,
      standings,
      matches,
    });
  } catch (err) {
    console.error('Error calculating tournament standings:', err);
    return res.status(500).json({ error: 'Internal server error.' });
  }
}

export async function createTournament(req: Request, res: Response) {
  const { name, format, startDate, endDate, participatingTeamIds, teamsCount, matchesCount } = req.body;

  if (!name) {
    return res.status(400).json({ error: 'Tournament name is required.' });
  }

  try {
    const tournamentId = `tourn_${Date.now()}`;
    const teamsList = Array.isArray(participatingTeamIds) ? participatingTeamIds : [];

    const tournament = await TournamentModel.create({
      id: tournamentId,
      name: name.trim(),
      format: format || 'T20',
      status: 'Upcoming',
      startDate: startDate || '',
      endDate: endDate || '',
      participatingTeamIds: teamsList,
      teamsCount: teamsCount || teamsList.length || 0,
      matchesCount: matchesCount || 0,
    });

    try {
      broadcastNotification({
        title: 'New Tournament Created 🏆',
        message: `${tournament.name} (${tournament.format}) has been officially scheduled!`,
        timestamp: new Date().toISOString(),
      });
    } catch (notifErr) {
      console.warn('Notification broadcast warning:', notifErr);
    }

    return res.status(201).json({ message: 'Tournament created successfully.', tournament });
  } catch (err) {
    console.error('Error creating tournament:', err);
    return res.status(500).json({ error: 'Internal server error.' });
  }
}

export async function updateTournament(req: Request, res: Response) {
  const { id } = req.params;
  const { name, format, status, startDate, endDate, participatingTeamIds, teamsCount, matchesCount } = req.body;

  try {
    const updateData: any = {};
    if (name !== undefined) updateData.name = name.trim();
    if (format !== undefined) updateData.format = format;
    if (status !== undefined) updateData.status = status;
    if (startDate !== undefined) updateData.startDate = startDate;
    if (endDate !== undefined) updateData.endDate = endDate;
    if (participatingTeamIds !== undefined) updateData.participatingTeamIds = participatingTeamIds;
    if (teamsCount !== undefined) updateData.teamsCount = teamsCount;
    if (matchesCount !== undefined) updateData.matchesCount = matchesCount;

    const updated = await TournamentModel.findOneAndUpdate(
      { id },
      { $set: updateData },
      { new: true }
    );

    if (!updated) {
      return res.status(404).json({ error: 'Tournament not found.' });
    }

    return res.status(200).json({ message: 'Tournament updated successfully.', tournament: updated });
  } catch (err) {
    console.error('Error updating tournament:', err);
    return res.status(500).json({ error: 'Internal server error.' });
  }
}

export async function deleteTournament(req: Request, res: Response) {
  const { id } = req.params;

  try {
    const deleted = await TournamentModel.findOneAndDelete({ id });
    if (!deleted) {
      return res.status(404).json({ error: 'Tournament not found.' });
    }

    return res.status(200).json({ message: 'Tournament deleted successfully.' });
  } catch (err) {
    console.error('Error deleting tournament:', err);
    return res.status(500).json({ error: 'Internal server error.' });
  }
}
