import { Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { pool } from '../config/db';

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
    const matchRes = await pool.query(
      'SELECT id, scorer_username, team_a_id, team_b_id FROM matches WHERE scorer_username = $1 AND scorer_password = $2',
      [email, password]
    );
    if (matchRes.rows.length > 0) {
      const match = matchRes.rows[0];
      const token = jwt.sign({ id: `scorer_${match.id}`, email, role: 'Scorer' }, JWT_SECRET, { expiresIn: '7d' });
      return res.status(200).json({
        token,
        user: { email, role: 'Scorer', name: `Official Scorer (${match.scorer_username})` },
        activeScorerMatchId: match.id
      });
    }

    // 3. User login check
    const userRes = await pool.query('SELECT * FROM users WHERE email = $1', [email]);
    if (userRes.rows.length > 0) {
      const user = userRes.rows[0];
      const isMatch = await bcrypt.compare(password, user.password_hash);
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
    const userCheck = await pool.query('SELECT id FROM users WHERE email = $1', [email]);
    if (userCheck.rows.length > 0) {
      return res.status(409).json({ error: 'Email is already registered.' });
    }

    const passwordHash = await bcrypt.hash(password, 10);
    const userId = `user_${Date.now()}`;
    const role = 'User';

    await pool.query(
      'INSERT INTO users (id, email, password_hash, role) VALUES ($1, $2, $3, $4)',
      [userId, email, passwordHash, role]
    );

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
