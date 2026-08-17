import { Router } from 'express';
import { getMatches, getMatchById, scheduleMatch, adminActivateMatch, resetMatch, getMatchPrediction } from '../controllers/matchController';
import { authenticateJWT, requireRole } from '../middleware/authMiddleware';

const router = Router();

// Public routes
router.get('/', getMatches);
router.get('/:id', getMatchById);
router.get('/:id/prediction', getMatchPrediction);

// Admin-only write routes
router.post('/', authenticateJWT, requireRole(['Admin']), scheduleMatch);
router.post('/:id/activate', authenticateJWT, requireRole(['Admin']), adminActivateMatch);
router.post('/:id/reset', authenticateJWT, requireRole(['Admin']), resetMatch);

export default router;
