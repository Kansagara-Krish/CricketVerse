import { Router } from 'express';
import { generateCommentaryVoice, generateCustomCommentary } from '../controllers/aiController';
import { authenticateJWT } from '../middleware/authMiddleware';

const router = Router();

router.post('/voice', generateCommentaryVoice);
router.post('/commentary', generateCustomCommentary);

export default router;
