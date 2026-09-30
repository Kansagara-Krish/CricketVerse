import { Router } from 'express';
import {
  getTeams,
  getTeamById,
  addTeam,
  updateTeam,
  deleteTeam,
  addPlayer,
  updatePlayer,
  removePlayer
} from '../controllers/teamController';
import { authenticateJWT, requireRole } from '../middleware/authMiddleware';

const router = Router();

router.get('/', getTeams);
router.get('/:id', getTeamById);
router.post('/', authenticateJWT, requireRole(['Admin']), addTeam);
router.put('/:id', authenticateJWT, requireRole(['Admin']), updateTeam);
router.delete('/:id', authenticateJWT, requireRole(['Admin']), deleteTeam);

router.post('/:teamId/players', authenticateJWT, requireRole(['Admin']), addPlayer);
router.put('/players/:id', authenticateJWT, requireRole(['Admin']), updatePlayer);
router.delete('/players/:playerId', authenticateJWT, requireRole(['Admin']), removePlayer);

export default router;
