import { Router } from 'express';
import {
  getNotifications,
  createNotification,
  markAsRead,
  clearNotifications,
} from '../controllers/notificationController';
import { authenticateJWT, requireRole } from '../middleware/authMiddleware';

const router = Router();

router.get('/', authenticateJWT, getNotifications);
router.post('/', authenticateJWT, requireRole(['Admin']), createNotification);
router.put('/:id/read', authenticateJWT, markAsRead);
router.delete('/clear', authenticateJWT, clearNotifications);

export default router;
