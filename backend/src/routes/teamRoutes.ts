import { Router } from 'express';
import { getTeams, addTeam, updateTeam, deleteTeam, addPlayer, updatePlayer, removePlayer } from '../controllers/teamController';
import { authenticateJWT, requireRole } from '../middleware/authMiddleware';

const router = Router();

// Public read routes
router.get('/', getTeams);

// Admin-only write routes
router.post('/', authenticateJWT, requireRole(['Admin']), addTeam);
router.put('/:id', authenticateJWT, requireRole(['Admin']), updateTeam);
router.delete('/:id', authenticateJWT, requireRole(['Admin']), deleteTeam);
router.post('/:teamId/players', authenticateJWT, requireRole(['Admin']), addPlayer);
router.put('/players/:id', authenticateJWT, requireRole(['Admin']), updatePlayer);
router.delete('/players/:playerId', authenticateJWT, requireRole(['Admin']), removePlayer);

export default router;
