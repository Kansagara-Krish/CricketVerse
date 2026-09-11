import { Router } from 'express';
import { getMatches, getMatchById, scheduleMatch, updateMatch, adminActivateMatch, resetMatch, getMatchPrediction, deleteMatch } from '../controllers/matchController';
import { authenticateJWT, requireRole } from '../middleware/authMiddleware';

const router = Router();

// Public routes
router.get('/', getMatches);
router.get('/:id', getMatchById);
router.get('/:id/prediction', getMatchPrediction);

// Admin-only write routes
router.post('/', authenticateJWT, requireRole(['Admin']), scheduleMatch);
router.put('/:id', authenticateJWT, requireRole(['Admin']), updateMatch);
router.delete('/:id', authenticateJWT, requireRole(['Admin']), deleteMatch);
router.post('/:id/activate', authenticateJWT, requireRole(['Admin']), adminActivateMatch);
router.post('/:id/reset', authenticateJWT, requireRole(['Admin']), resetMatch);

export default router;
