import { Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import { ManagerModel } from '../models/Manager';
import { UserModel } from '../models/User';

export async function getManagers(req: Request, res: Response) {
  try {
    const managers = await ManagerModel.find().sort({ createdAt: -1 }).lean();
    return res.status(200).json(managers);
  } catch (err) {
    console.error('Error fetching managers:', err);
    return res.status(500).json({ error: 'Internal server error fetching managers.' });
  }
}

export async function createManager(req: Request, res: Response) {
  const { name, username, password, phone } = req.body;

  if (!name || !username || !password) {
    return res.status(400).json({ error: 'Name, username and password are required.' });
  }

  const cleanName = String(name).trim();
  const cleanUsername = String(username).trim().toLowerCase();
  const cleanPassword = String(password).trim();
  const cleanPhone = phone ? String(phone).trim() : '';

  try {
    const existing = await ManagerModel.findOne({ username: cleanUsername });
    if (existing) {
      return res.status(409).json({ error: 'A manager with this username already exists.' });
    }

    const managerId = `mgr_${Date.now()}`;
    const newManager = await ManagerModel.create({
      id: managerId,
      name: cleanName,
      username: cleanUsername,
      password: cleanPassword,
      phone: cleanPhone,
    });

    // Also register in UserModel as Scorer so they can authenticate seamlessly
    try {
      const existingUser = await UserModel.findOne({ email: cleanUsername });
      if (!existingUser) {
        const passwordHash = await bcrypt.hash(cleanPassword, 10);
        await UserModel.create({
          id: `user_${managerId}`,
          email: cleanUsername,
          passwordHash,
          role: 'Scorer',
          name: cleanName,
        });
      }
    } catch (uErr) {
      console.warn('Could not mirror manager to UserModel (non-fatal):', uErr);
    }

    return res.status(201).json({
      message: 'Manager created successfully.',
      manager: newManager,
    });
  } catch (err: any) {
    console.error('Error creating manager:', err);
    if (err && (err.code === 11000 || err.message?.includes('duplicate key'))) {
      return res.status(409).json({ error: 'A manager with this username already exists.' });
    }
    return res.status(500).json({ error: 'Internal server error creating manager.' });
  }
}

export async function deleteManager(req: Request, res: Response) {
  const { id } = req.params;
  try {
    const deleted = await ManagerModel.findOneAndDelete({ id });
    if (!deleted) {
      return res.status(404).json({ error: 'Manager not found.' });
    }

    // Also remove associated user account from UserModel if created
    try {
      await UserModel.findOneAndDelete({ email: deleted.username.toLowerCase() });
    } catch (uErr) {
      console.warn('Could not remove manager from UserModel:', uErr);
    }

    return res.status(200).json({ message: 'Manager credential deleted successfully.' });
  } catch (err) {
    console.error('Error deleting manager:', err);
    return res.status(500).json({ error: 'Internal server error deleting manager.' });
  }
}
