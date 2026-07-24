import { Router } from 'express';
import { startMatchSetup, updateScore, undoLastBall, swapStrikers, switchBowler, endInningsOrMatch, endMatchForce } from '../controllers/scoringController';
import { authenticateJWT, requireRole } from '../middleware/authMiddleware';

const router = Router();

// Scorer and Admin authorized scoring endpoints
router.post('/:matchId/toss', authenticateJWT, requireRole(['Admin', 'Scorer']), startMatchSetup);
router.post('/:matchId/ball', authenticateJWT, requireRole(['Admin', 'Scorer']), updateScore);
router.post('/:matchId/undo', authenticateJWT, requireRole(['Admin', 'Scorer']), undoLastBall);
router.post('/:matchId/swap-strike', authenticateJWT, requireRole(['Admin', 'Scorer']), swapStrikers);
router.post('/:matchId/switch-bowler', authenticateJWT, requireRole(['Admin', 'Scorer']), switchBowler);
router.post('/:matchId/end-innings', authenticateJWT, requireRole(['Admin', 'Scorer']), endInningsOrMatch);
router.post('/:matchId/end-match', authenticateJWT, requireRole(['Admin', 'Scorer']), endMatchForce);

export default router;
