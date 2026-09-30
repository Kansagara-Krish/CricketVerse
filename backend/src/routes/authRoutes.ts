import { Router } from 'express';
import {
  login,
  register,
  getMe,
  updateProfile,
  requestPasswordOtp,
  updatePassword,
  broadcastNotificationEndpoint,
  logout
} from '../controllers/authController';
import { authenticateJWT, requireRole } from '../middleware/authMiddleware';

const router = Router();

router.post('/login', login);
router.post('/register', register);
router.get('/me', authenticateJWT, getMe);
router.put('/profile', authenticateJWT, updateProfile);
router.post('/password-otp', authenticateJWT, requestPasswordOtp);
router.put('/password', authenticateJWT, updatePassword);
router.post('/broadcast', broadcastNotificationEndpoint);
router.post('/logout', logout);

export default router;
