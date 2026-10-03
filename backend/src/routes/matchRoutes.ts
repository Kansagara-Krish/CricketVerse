import { Router } from 'express';
import {
  getMatches,
  getMatchById,
  scheduleMatch,
  updateMatch,
  adminActivateMatch,
  resetMatch,
  deleteMatch,
  getMatchPrediction
} from '../controllers/matchController';
import { authenticateJWT, requireRole } from '../middleware/authMiddleware';

const router = Router();

router.get('/', getMatches);
router.get('/:id', getMatchById);
router.get('/:id/prediction', getMatchPrediction);

router.post('/', authenticateJWT, requireRole(['Admin']), scheduleMatch);
router.put('/:id', authenticateJWT, requireRole(['Admin']), updateMatch);
router.delete('/:id', authenticateJWT, requireRole(['Admin']), deleteMatch);
router.post('/:id/activate', authenticateJWT, requireRole(['Admin']), adminActivateMatch);
router.post('/:id/reset', authenticateJWT, requireRole(['Admin', 'Scorer']), resetMatch);

export default router;
