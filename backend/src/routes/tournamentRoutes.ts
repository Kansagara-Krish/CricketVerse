import { Router } from 'express';
import {
  getTournaments,
  getTournamentById,
  createTournament,
  updateTournament,
  deleteTournament,
} from '../controllers/tournamentController';
import { authenticateJWT, requireRole } from '../middleware/authMiddleware';

const router = Router();

router.get('/', getTournaments);
router.get('/:id', getTournamentById);
router.post('/', authenticateJWT, requireRole(['Admin']), createTournament);
router.put('/:id', authenticateJWT, requireRole(['Admin']), updateTournament);
router.delete('/:id', authenticateJWT, requireRole(['Admin']), deleteTournament);

export default router;
