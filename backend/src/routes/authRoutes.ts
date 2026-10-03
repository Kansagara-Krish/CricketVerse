import { Router } from 'express';
import {
  login,
  register,
  getMe,
  updateProfile,
  requestPasswordOtp,
  updatePassword,
  requestForgotPasswordOtp,
  verifyForgotPasswordOtp,
  resetForgotPassword,
  getEmailConfigEndpoint,
  updateEmailConfigEndpoint,
  testEmailConfigEndpoint,
  broadcastNotificationEndpoint,
  logout
} from '../controllers/authController';
import { authenticateJWT, requireRole } from '../middleware/authMiddleware';

const router = Router();

// Standard Auth
router.post('/login', login);
router.post('/register', register);
router.get('/me', authenticateJWT, getMe);
router.put('/profile', authenticateJWT, updateProfile);
router.post('/logout', logout);

// In-app password change for authenticated users
router.post('/password-otp', authenticateJWT, requestPasswordOtp);
router.put('/password', authenticateJWT, updatePassword);

// Public Forgot Password flow for Users & Admin
router.post('/forgot-password/request-otp', requestForgotPasswordOtp);
router.post('/forgot-password/verify-otp', verifyForgotPasswordOtp);
router.post('/forgot-password/reset-password', resetForgotPassword);

// Admin-only Email Sender & App Password Configuration
router.get('/email-config', authenticateJWT, requireRole(['Admin']), getEmailConfigEndpoint);
router.put('/email-config', authenticateJWT, requireRole(['Admin']), updateEmailConfigEndpoint);
router.post('/email-config/test', authenticateJWT, requireRole(['Admin']), testEmailConfigEndpoint);

// Notifications
router.post('/broadcast', broadcastNotificationEndpoint);

export default router;
