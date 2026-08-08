import { Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { prisma } from '../config/db';
import { broadcastNotification } from '../sockets/socketHandler';

const JWT_SECRET = process.env.JWT_SECRET || 'cricketverse_super_secret_key_123!';

const passwordOtpMap = new Map<string, { otp: string; expiresAt: number }>();

export async function login(req: Request, res: Response) {
  const { email, password } = req.body;
  
  if (!email || !password) {
    return res.status(400).json({ error: 'Email/username and password are required.' });
  }

  try {
    // 1. Admin login check
    if (email === 'admin@cricketverse.ai' && password === 'admin123') {
      const token = jwt.sign({ id: 'admin_user', email, role: 'Admin' }, JWT_SECRET, { expiresIn: '7d' });
      // Fetch or seed Rajesh Kumar's admin details if not in DB
      let adminName = 'Rajesh Kumar';
      const adminInDb = await prisma.user.findUnique({ where: { id: 'admin_user' } });
      if (adminInDb) {
        adminName = adminInDb.name || adminName;
      }
      return res.status(200).json({
        token,
        user: { email, role: 'Admin', name: adminName }
      });
    }

    // 2. Scorer / Manager login check
    const match = await prisma.match.findFirst({
      where: {
        scorerUsername: email,
        scorerPassword: password,
      },
      select: {
        id: true,
        scorerUsername: true,
        teamAId: true,
        teamBId: true,
      },
    });

    if (match) {
      const token = jwt.sign({ id: `scorer_${match.id}`, email, role: 'Scorer' }, JWT_SECRET, { expiresIn: '7d' });
      return res.status(200).json({
        token,
        user: { email, role: 'Scorer', name: `Official Scorer (${match.scorerUsername})` },
        activeScorerMatchId: match.id
      });
    }

    // 3. User login check
    const user = await prisma.user.findUnique({ where: { email } });
    if (user) {
      const isMatch = await bcrypt.compare(password, user.passwordHash);
      if (isMatch) {
        const token = jwt.sign({ id: user.id, email: user.email, role: user.role }, JWT_SECRET, { expiresIn: '7d' });
        return res.status(200).json({
          token,
          user: { email: user.email, role: user.role, name: user.name || user.email.split('@')[0] }
        });
      }
    }

    return res.status(401).json({ error: 'Invalid credentials.' });
  } catch (err) {
    console.error('Login error:', err);
    return res.status(500).json({ error: 'Internal server error.' });
  }
}

export async function register(req: Request, res: Response) {
  const { email, password, name } = req.body;

  if (!email || !password) {
    return res.status(400).json({ error: 'Email and password are required.' });
  }

  try {
    // Check if email already registered
    const existingUser = await prisma.user.findUnique({ where: { email } });
    if (existingUser) {
      return res.status(409).json({ error: 'Email is already registered.' });
    }

    const passwordHash = await bcrypt.hash(password, 10);
    const userId = `user_${Date.now()}`;
    const role = 'User';
    const finalName = name || email.split('@')[0];

    await prisma.user.create({
      data: {
        id: userId,
        email,
        passwordHash,
        role,
        name: finalName,
      },
    });

    const token = jwt.sign({ id: userId, email, role }, JWT_SECRET, { expiresIn: '7d' });
    return res.status(201).json({
      token,
      user: { email, role, name: finalName }
    });
  } catch (err) {
    console.error('Registration error:', err);
    return res.status(500).json({ error: 'Internal server error.' });
  }
}

export async function getMe(req: any, res: Response) {
  let activeScorerMatchId: string | null = null;
  if (req.user && req.user.role === 'Scorer' && req.user.id && req.user.id.startsWith('scorer_')) {
    activeScorerMatchId = req.user.id.substring(7);
  }

  let userDetails = { ...req.user };
  if (req.user && req.user.role !== 'Scorer') {
    const dbUser = await prisma.user.findUnique({ where: { id: req.user.id } });
    if (dbUser) {
      userDetails.name = dbUser.name || dbUser.email.split('@')[0];
    }
  } else if (req.user && req.user.role === 'Scorer') {
    userDetails.name = `Official Scorer`;
  }

  return res.status(200).json({
    user: userDetails,
    activeScorerMatchId
  });
}

export async function updateProfile(req: any, res: Response) {
  const { name, email } = req.body;
  if (!req.user || !req.user.id) {
    return res.status(401).json({ error: 'Unauthorized.' });
  }

  if (req.user.role === 'Scorer') {
    return res.status(400).json({ error: 'Scorer profile cannot be modified.' });
  }

  try {
    if (email) {
      const existingUser = await prisma.user.findFirst({
        where: {
          email,
          id: { not: req.user.id }
        }
      });
      if (existingUser) {
        return res.status(409).json({ error: 'Email is already taken by another user.' });
      }
    }

    const updatedUser = await prisma.user.update({
      where: { id: req.user.id },
      data: {
        ...(name !== undefined && { name }),
        ...(email !== undefined && { email })
      }
    });

    const token = jwt.sign({ id: updatedUser.id, email: updatedUser.email, role: updatedUser.role }, JWT_SECRET, { expiresIn: '7d' });

    return res.status(200).json({
      token,
      user: {
        email: updatedUser.email,
        role: updatedUser.role,
        name: updatedUser.name
      }
    });
  } catch (err) {
    console.error('Update profile error:', err);
    return res.status(500).json({ error: 'Internal server error.' });
  }
}

export async function requestPasswordOtp(req: any, res: Response) {
  if (!req.user || !req.user.id) {
    return res.status(401).json({ error: 'Unauthorized.' });
  }

  const otp = Math.floor(1000 + Math.random() * 9000).toString();
  const expiresAt = Date.now() + 10 * 60 * 1000; // 10 minutes

  passwordOtpMap.set(req.user.id, { otp, expiresAt });
  console.log(`Generated OTP for user ${req.user.id}: ${otp}`);

  return res.status(200).json({
    message: 'OTP generated successfully.',
    otp
  });
}

export async function updatePassword(req: any, res: Response) {
  const { otp, newPassword } = req.body;

  if (!req.user || !req.user.id) {
    return res.status(401).json({ error: 'Unauthorized.' });
  }

  if (!otp || !newPassword) {
    return res.status(400).json({ error: 'OTP and new password are required.' });
  }

  const storedData = passwordOtpMap.get(req.user.id);
  if (!storedData) {
    return res.status(400).json({ error: 'No OTP requested for this user.' });
  }

  if (Date.now() > storedData.expiresAt) {
    passwordOtpMap.delete(req.user.id);
    return res.status(400).json({ error: 'OTP has expired.' });
  }

  if (storedData.otp !== otp) {
    return res.status(400).json({ error: 'Invalid OTP.' });
  }

  try {
    const passwordHash = await bcrypt.hash(newPassword, 10);

    await prisma.user.update({
      where: { id: req.user.id },
      data: { passwordHash }
    });

    passwordOtpMap.delete(req.user.id);

    return res.status(200).json({ message: 'Password updated successfully.' });
  } catch (err) {
    console.error('Update password error:', err);
    return res.status(500).json({ error: 'Internal server error.' });
  }
}

export async function broadcastNotificationEndpoint(req: any, res: Response) {
  const { title, message } = req.body;
  if (!title || !message) {
    return res.status(400).json({ error: 'Title and message are required.' });
  }

  try {
    broadcastNotification({
      title,
      message,
      timestamp: new Date().toISOString()
    });
    return res.status(200).json({ message: 'Notification broadcasted successfully.' });
  } catch (err) {
    console.error('Broadcast notification error:', err);
    return res.status(500).json({ error: 'Internal server error.' });
  }
}
