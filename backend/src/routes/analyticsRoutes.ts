import { Router } from 'express';
import { getSystemAnalytics } from '../controllers/analyticsController';

const router = Router();

router.get('/stats', getSystemAnalytics);

export default router;
