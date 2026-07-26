import { Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { prisma } from '../config/db';

const JWT_SECRET = process.env.JWT_SECRET || 'cricketverse_super_secret_key_123!';

export async function login(req: Request, res: Response) {
  const { email, password } = req.body;
  
  if (!email || !password) {
    return res.status(400).json({ error: 'Email/username and password are required.' });
  }

  try {
    // 1. Admin login check
    if (email === 'admin@cricketverse.ai' && password === 'admin123') {
      const token = jwt.sign({ id: 'admin_user', email, role: 'Admin' }, JWT_SECRET, { expiresIn: '7d' });
      return res.status(200).json({
        token,
        user: { email, role: 'Admin', name: 'Rajesh Kumar' }
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
          user: { email: user.email, role: user.role, name: user.email.split('@')[0] }
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
  const { email, password } = req.body;

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

    await prisma.user.create({
      data: {
        id: userId,
        email,
        passwordHash,
        role,
      },
    });

    const token = jwt.sign({ id: userId, email, role }, JWT_SECRET, { expiresIn: '7d' });
    return res.status(201).json({
      token,
      user: { email, role, name: email.split('@')[0] }
    });
  } catch (err) {
    console.error('Registration error:', err);
    return res.status(500).json({ error: 'Internal server error.' });
  }
}

export async function getMe(req: any, res: Response) {
  return res.status(200).json({ user: req.user });
}
