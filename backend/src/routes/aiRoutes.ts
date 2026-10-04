import { Router } from 'express';
import {
  generateCommentaryVoice,
  generateCustomCommentary,
  getAiConfig,
  updateAiConfig,
  testElevenLabsKey,
} from '../controllers/aiController';
import { authenticateJWT } from '../middleware/authMiddleware';

const router = Router();

// Centralized ElevenLabs Configuration
router.get('/config', getAiConfig);
router.post('/config', authenticateJWT, updateAiConfig);
router.put('/config', authenticateJWT, updateAiConfig);
router.post('/test-key', authenticateJWT, testElevenLabsKey);

// Commentary & Voice TTS
router.post('/voice', generateCommentaryVoice);
router.post('/commentary', generateCustomCommentary);

export default router;
