import { Request, Response } from 'express';
import { MatchModel } from '../models/Match';
import { TeamModel } from '../models/Team';
import { TournamentModel } from '../models/Tournament';

export async function getSystemAnalytics(req: Request, res: Response) {
  try {
    const totalMatches = await MatchModel.countDocuments();
    const liveMatches = await MatchModel.countDocuments({ status: 'Live' });
    const completedMatches = await MatchModel.countDocuments({ status: 'Completed' });
    const upcomingMatches = await MatchModel.countDocuments({ status: 'Upcoming' });
    const totalTeams = await TeamModel.countDocuments();
    const totalTournaments = await TournamentModel.countDocuments();

    // Aggregate top batsmen and bowlers across all teams
    const teams = await TeamModel.find().lean();
    const allPlayers: any[] = [];
    teams.forEach((t: any) => {
      (t.players || []).forEach((p: any) => {
        allPlayers.push({
          ...p,
          teamName: t.name,
          teamShort: t.shortName,
        });
      });
    });

    const topBatsmen = [...allPlayers]
      .sort((a, b) => (b.runsScored || 0) - (a.runsScored || 0))
      .slice(0, 5);

    const topBowlers = [...allPlayers]
      .sort((a, b) => (b.wicketsTaken || 0) - (a.wicketsTaken || 0))
      .slice(0, 5);

    return res.status(200).json({
      summary: {
        totalTournaments,
        totalTeams,
        totalMatches,
        liveMatches,
        completedMatches,
        upcomingMatches,
        totalPlayers: allPlayers.length,
      },
      topBatsmen,
      topBowlers,
    });
  } catch (err) {
    console.error('Error fetching system analytics:', err);
    return res.status(500).json({ error: 'Internal server error.' });
  }
}
