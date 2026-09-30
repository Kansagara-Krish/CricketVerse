import { Router } from 'express';
import {
  startMatchSetup,
  updateScore,
  undoLastBall,
  swapStrikers,
  switchBowler,
  endInningsOrMatch,
  endMatchForce
} from '../controllers/scoringController';
import { authenticateJWT, requireRole } from '../middleware/authMiddleware';

const router = Router();

router.post('/:matchId/toss', authenticateJWT, requireRole(['Scorer', 'Admin', 'Manager']), startMatchSetup);
router.post('/:matchId/ball', authenticateJWT, requireRole(['Scorer', 'Admin', 'Manager']), updateScore);
router.post('/:matchId/undo', authenticateJWT, requireRole(['Scorer', 'Admin', 'Manager']), undoLastBall);
router.post('/:matchId/swap-strike', authenticateJWT, requireRole(['Scorer', 'Admin', 'Manager']), swapStrikers);
router.post('/:matchId/switch-bowler', authenticateJWT, requireRole(['Scorer', 'Admin', 'Manager']), switchBowler);
router.post('/:matchId/end-innings', authenticateJWT, requireRole(['Scorer', 'Admin', 'Manager']), endInningsOrMatch);
router.post('/:matchId/end-match', authenticateJWT, requireRole(['Scorer', 'Admin', 'Manager']), endMatchForce);

export default router;
