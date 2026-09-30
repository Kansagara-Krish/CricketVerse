import { Request, Response } from 'express';
import { TournamentModel } from '../models/Tournament';
import { MatchModel } from '../models/Match';
import { broadcastNotification } from '../sockets/socketHandler';

export async function getTournaments(req: Request, res: Response) {
  try {
    const tournaments = await TournamentModel.find().sort({ createdAt: -1 }).lean();
    return res.status(200).json(tournaments);
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
    return res.status(200).json(tournament);
  } catch (err) {
    console.error('Error fetching tournament by id:', err);
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
