import { Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { UserModel } from '../models/User';
import { MatchModel } from '../models/Match';
import { broadcastNotification } from '../sockets/socketHandler';

const JWT_SECRET = process.env.JWT_SECRET || 'cricketverse_super_secret_key_123!';

const passwordOtpMap = new Map<string, { otp: string; expiresAt: number }>();

export interface RegistrationValidationResult {
  isValid: boolean;
  error?: string;
  field?: 'email' | 'password' | 'confirmPassword' | 'name';
}

export function validateRegistrationInput(
  email: any,
  password: any,
  confirmPassword?: any,
  name?: any
): RegistrationValidationResult {
  if (!email || typeof email !== 'string' || email.trim().length === 0) {
    return { isValid: false, error: 'Email is required.', field: 'email' };
  }

  const trimmedEmail = email.trim();

  if (/\s/.test(trimmedEmail)) {
    return { isValid: false, error: 'Email cannot contain spaces.', field: 'email' };
  }

  const atMatches = trimmedEmail.match(/@/g);
  if (!atMatches || atMatches.length !== 1) {
    return { isValid: false, error: 'Please enter a valid email address.', field: 'email' };
  }

  const emailRegex = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
  if (!emailRegex.test(trimmedEmail)) {
    return { isValid: false, error: 'Please enter a valid email address.', field: 'email' };
  }

  const [localPart, domainPart] = trimmedEmail.split('@');
  if (!localPart || !domainPart || domainPart.startsWith('.') || domainPart.endsWith('.') || domainPart.indexOf('.') === -1) {
    return { isValid: false, error: 'Please enter a valid email address.', field: 'email' };
  }

  if (!password || typeof password !== 'string' || password.length === 0) {
    return { isValid: false, error: 'Password is required.', field: 'password' };
  }

  if (/\s/.test(password)) {
    return { isValid: false, error: 'Password cannot contain spaces.', field: 'password' };
  }

  if (password.length < 8) {
    return { isValid: false, error: 'Password must be at least 8 characters long.', field: 'password' };
  }

  if (!/[A-Z]/.test(password)) {
    return { isValid: false, error: 'Password must contain at least one uppercase letter.', field: 'password' };
  }

  if (!/[a-z]/.test(password)) {
    return { isValid: false, error: 'Password must contain at least one lowercase letter.', field: 'password' };
  }

  if (!/[0-9]/.test(password)) {
    return { isValid: false, error: 'Password must contain at least one number.', field: 'password' };
  }

  const specialCharRegex = /[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]/;
  if (!specialCharRegex.test(password)) {
    return { isValid: false, error: 'Password must contain at least one special symbol (!@#$%^&*...).', field: 'password' };
  }

  if (confirmPassword !== undefined && confirmPassword !== null) {
    if (confirmPassword !== password) {
      return { isValid: false, error: 'Passwords do not match.', field: 'confirmPassword' };
    }
  }

  return { isValid: true };
}

export async function login(req: Request, res: Response) {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ error: 'Email/username and password are required.' });
  }

  const rawEmail = typeof email === 'string' ? email.trim() : '';
  const normalizedEmail = rawEmail.toLowerCase();

  try {
    // 1. Admin direct login check
    if ((normalizedEmail === 'admin@gmail.com' || rawEmail === 'admin@gmail.com') && password === 'admin123') {
      const token = jwt.sign({ id: 'admin_user', email: 'admin@gmail.com', role: 'Admin' }, JWT_SECRET, { expiresIn: '7d' });
      let adminName = 'Rajesh Kumar';
      const adminInDb = await UserModel.findOne({ id: 'admin_user' });
      if (adminInDb && adminInDb.name) {
        adminName = adminInDb.name;
      }
      return res.status(200).json({
        token,
        user: { id: 'admin_user', email: 'admin@gmail.com', role: 'Admin', name: adminName }
      });
    }

    // 2. Scorer / Manager login check against active matches
    let match = await MatchModel.findOne({
      scorerUsername: rawEmail,
      scorerPassword: password,
    });

    if (!match && rawEmail !== normalizedEmail) {
      match = await MatchModel.findOne({
        scorerUsername: normalizedEmail,
        scorerPassword: password,
      });
    }

    if (match) {
      const token = jwt.sign({ id: `scorer_${match.id}`, email: match.scorerUsername, role: 'Scorer' }, JWT_SECRET, { expiresIn: '7d' });
      return res.status(200).json({
        token,
        user: { id: `scorer_${match.id}`, email: match.scorerUsername, role: 'Scorer', name: `Official Scorer (${match.scorerUsername})` },
        activeScorerMatchId: match.id
      });
    }

    // 3. User login check
    let user = await UserModel.findOne({ email: normalizedEmail });
    if (!user && rawEmail !== normalizedEmail) {
      user = await UserModel.findOne({ email: rawEmail });
    }

    if (user) {
      const isMatch = await bcrypt.compare(password, user.passwordHash);
      if (isMatch) {
        const token = jwt.sign({ id: user.id, email: user.email, role: user.role }, JWT_SECRET, { expiresIn: '7d' });
        return res.status(200).json({
          token,
          user: { id: user.id, email: user.email, role: user.role, name: user.name || user.email.split('@')[0] }
        });
      }
    }

    return res.status(401).json({ error: 'Invalid email or password.' });
  } catch (err) {
    console.error('Login error:', err);
    return res.status(500).json({ error: 'Internal server error.' });
  }
}

export async function register(req: Request, res: Response) {
  const { email, password, confirmPassword, name } = req.body;

  const validation = validateRegistrationInput(email, password, confirmPassword, name);
  if (!validation.isValid) {
    return res.status(400).json({
      error: validation.error,
      field: validation.field,
    });
  }

  const normalizedEmail = (email as string).trim().toLowerCase();
  const trimmedName = typeof name === 'string' ? name.trim() : '';
  const finalName = trimmedName || normalizedEmail.split('@')[0];

  try {
    const existingUser = await UserModel.findOne({ email: normalizedEmail });
    if (existingUser) {
      return res.status(409).json({
        error: 'An account with this email already exists.',
        field: 'email',
      });
    }

    const passwordHash = await bcrypt.hash(password, 10);
    const userId = `user_${Date.now()}`;
    const role = 'User';

    const newUser = await UserModel.create({
      id: userId,
      email: normalizedEmail,
      passwordHash,
      role,
      name: finalName,
    });

    const token = jwt.sign({ id: userId, email: normalizedEmail, role }, JWT_SECRET, { expiresIn: '7d' });
    return res.status(201).json({
      token,
      user: { id: userId, email: normalizedEmail, role, name: finalName }
    });
  } catch (err: any) {
    if (err && (err.code === 11000 || err.message?.includes('duplicate key'))) {
      return res.status(409).json({
        error: 'An account with this email already exists.',
        field: 'email',
      });
    }

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
    const dbUser = await UserModel.findOne({ id: req.user.id });
    if (dbUser) {
      userDetails.name = dbUser.name || dbUser.email.split('@')[0];
      userDetails.favoriteTeams = dbUser.favoriteTeams || [];
      userDetails.notificationSettings = dbUser.notificationSettings || {};
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
  const { name, email, favoriteTeams, notificationSettings } = req.body;
  if (!req.user || !req.user.id) {
    return res.status(401).json({ error: 'Unauthorized.' });
  }

  if (req.user.role === 'Scorer') {
    return res.status(400).json({ error: 'Scorer profile cannot be modified.' });
  }

  try {
    if (email) {
      const normalizedEmail = email.trim().toLowerCase();
      const existingUser = await UserModel.findOne({
        email: normalizedEmail,
        id: { $ne: req.user.id }
      });
      if (existingUser) {
        return res.status(409).json({ error: 'Email is already taken by another user.' });
      }
    }

    const updateFields: any = {};
    if (name !== undefined) updateFields.name = name.trim();
    if (email !== undefined) updateFields.email = email.trim().toLowerCase();
    if (favoriteTeams !== undefined) updateFields.favoriteTeams = favoriteTeams;
    if (notificationSettings !== undefined) updateFields.notificationSettings = notificationSettings;

    const updatedUser = await UserModel.findOneAndUpdate(
      { id: req.user.id },
      { $set: updateFields },
      { new: true }
    );

    if (!updatedUser) {
      return res.status(404).json({ error: 'User not found.' });
    }

    const token = jwt.sign({ id: updatedUser.id, email: updatedUser.email, role: updatedUser.role }, JWT_SECRET, { expiresIn: '7d' });

    return res.status(200).json({
      token,
      user: {
        id: updatedUser.id,
        email: updatedUser.email,
        role: updatedUser.role,
        name: updatedUser.name,
        favoriteTeams: updatedUser.favoriteTeams,
        notificationSettings: updatedUser.notificationSettings,
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
  const expiresAt = Date.now() + 10 * 60 * 1000;

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

    await UserModel.findOneAndUpdate(
      { id: req.user.id },
      { $set: { passwordHash } }
    );

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

export async function logout(req: any, res: Response) {
  try {
    let user = req.user;

    if (!user && req.headers?.authorization) {
      try {
        const token = req.headers.authorization.split(' ')[1];
        if (token) {
          const decoded = jwt.verify(token, JWT_SECRET) as any;
          user = {
            id: decoded.id,
            email: decoded.email,
            role: decoded.role,
          };
        }
      } catch (_) {}
    }

    const { name, email, role } = req.body || {};

    const displayName = user?.name || name || user?.email?.split('@')[0] || (email ? email.split('@')[0] : 'A user');
    const userEmail = user?.email || email || '';
    const userRole = user?.role || role || 'User';

    const identifierText = userEmail ? `${displayName} (${userEmail})` : `${displayName} (${userRole})`;

    broadcastNotification({
      title: 'User Signed Out',
      message: `${identifierText} has signed out of CricketVerse.`,
      timestamp: new Date().toISOString(),
    });

    return res.status(200).json({ message: 'Successfully logged out.' });
  } catch (err) {
    console.error('Logout controller error:', err);
    return res.status(500).json({ error: 'Internal server error.' });
  }
}
