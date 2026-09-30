import { Request, Response } from 'express';
import { NotificationModel } from '../models/Notification';
import { broadcastNotification } from '../sockets/socketHandler';

export async function getNotifications(req: any, res: Response) {
  try {
    const userId = req.user?.id || 'global';
    const notifications = await NotificationModel.find({
      $or: [{ userId: 'global' }, { userId }],
    })
      .sort({ createdAt: -1 })
      .limit(50)
      .lean();

    return res.status(200).json(notifications);
  } catch (err) {
    console.error('Error fetching notifications:', err);
    return res.status(500).json({ error: 'Internal server error.' });
  }
}

export async function createNotification(req: Request, res: Response) {
  const { title, message, category, userId } = req.body;

  if (!title || !message) {
    return res.status(400).json({ error: 'Title and message are required.' });
  }

  try {
    const notifId = `notif_${Date.now()}`;
    const notification = await NotificationModel.create({
      id: notifId,
      userId: userId || 'global',
      title: title.trim(),
      message: message.trim(),
      category: category || 'General',
      readBy: [],
    });

    broadcastNotification({
      title: notification.title,
      message: notification.message,
      timestamp: new Date().toISOString(),
    });

    return res.status(201).json({ message: 'Notification created.', notification });
  } catch (err) {
    console.error('Error creating notification:', err);
    return res.status(500).json({ error: 'Internal server error.' });
  }
}

export async function markAsRead(req: any, res: Response) {
  const { id } = req.params;
  const userId = req.user?.id || 'anonymous';

  try {
    await NotificationModel.findOneAndUpdate(
      { id },
      { $addToSet: { readBy: userId } }
    );
    return res.status(200).json({ message: 'Marked as read.' });
  } catch (err) {
    console.error('Error marking notification as read:', err);
    return res.status(500).json({ error: 'Internal server error.' });
  }
}

export async function clearNotifications(req: any, res: Response) {
  try {
    const userId = req.user?.id;
    if (userId) {
      await NotificationModel.deleteMany({ userId });
    }
    return res.status(200).json({ message: 'Notifications cleared.' });
  } catch (err) {
    console.error('Error clearing notifications:', err);
    return res.status(500).json({ error: 'Internal server error.' });
  }
}
