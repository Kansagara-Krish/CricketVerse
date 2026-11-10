import { Server, Socket } from 'socket.io';
import { createAdapter } from '@socket.io/redis-adapter';
import { redis } from '../config/redis';

let ioInstance: Server | null = null;

export function initSocketIO(server: any) {
  const io = new Server(server, {
    cors: {
      origin: '*',
      methods: ['GET', 'POST'],
    },
  });

  // If redis is available, hook up the redis adapter for Socket.IO scaling
  if (redis) {
    try {
      const pubClient = redis;
      const subClient = redis.duplicate();
      subClient.on('error', (err) => {
        console.warn('Redis Socket.IO subClient notice:', err.message);
      });
      io.adapter(createAdapter(pubClient, subClient));
      console.log('Socket.IO Redis adapter enabled.');
    } catch (err: any) {
      console.warn('Socket.IO Redis adapter skipped:', err.message);
    }
  }

  io.on('connection', (socket: Socket) => {
    console.log(`Socket connected: ${socket.id}`);

    // Join / leave match room
    socket.on('join_match', (data: { matchId: string }) => {
      if (data && data.matchId) {
        socket.join(`match:${data.matchId}`);
        console.log(`Socket ${socket.id} joined room match:${data.matchId}`);
      }
    });

    socket.on('leave_match', (data: { matchId: string }) => {
      if (data && data.matchId) {
        socket.leave(`match:${data.matchId}`);
        console.log(`Socket ${socket.id} left room match:${data.matchId}`);
      }
    });

    // Join / leave user-specific private room
    socket.on('join_user', (data: { userId: string }) => {
      if (data && data.userId) {
        socket.join(`user:${data.userId}`);
        console.log(`Socket ${socket.id} joined room user:${data.userId}`);
      }
    });

    socket.on('leave_user', (data: { userId: string }) => {
      if (data && data.userId) {
        socket.leave(`user:${data.userId}`);
        console.log(`Socket ${socket.id} left room user:${data.userId}`);
      }
    });

    // Relay milestone celebrations from clients to the match room & globally
    socket.on('milestone_celebration', (data: any) => {
      if (data && data.matchId) {
        console.log(`[MILESTONE_DEBUG] Socket received client milestone_celebration relay request:`, data.type, data.batsmanName);
        broadcastMilestoneCelebration(data.matchId, data);
      }
    });

    socket.on('disconnect', () => {
      console.log(`Socket disconnected: ${socket.id}`);
    });
  });

  ioInstance = io;
  return io;
}

export function broadcastMatchUpdate(matchId: string, eventName: string, payload: any) {
  if (ioInstance) {
    // 1. Emit to specific match room
    ioInstance.to(`match:${matchId}`).emit(eventName, payload);
    // 2. Broadcast globally so admin dashboard, manager portal, and user tabs receive live updates instantly
    ioInstance.emit(eventName, payload);
    ioInstance.emit('global_match_update', payload);
    console.log(`Broadcasted event ${eventName} to room match:${matchId} and globally.`);
  } else {
    console.warn('Socket.IO instance not initialized. Broadcast skipped.');
  }
}

export function broadcastTeamUpdate(eventName: string, payload: any) {
  if (ioInstance) {
    ioInstance.emit(eventName, payload);
    ioInstance.emit('global_team_update', payload);
    console.log(`Broadcasted team event ${eventName} globally.`);
  } else {
    console.warn('Socket.IO instance not initialized. Broadcast skipped.');
  }
}

export function broadcastNotification(payload: { title: string; message: string; timestamp?: string }) {
  if (ioInstance) {
    ioInstance.emit('global_notification', payload);
    console.log(`Broadcasted global notification: ${payload.title}`);
  } else {
    console.warn('Socket.IO instance not initialized. Broadcast skipped.');
  }
}

export function sendUserNotification(userId: string, payload: { title: string; message: string; timestamp?: string }) {
  if (ioInstance) {
    ioInstance.to(`user:${userId}`).emit('user_notification', payload);
    console.log(`Sent targeted notification to user:${userId} -> ${payload.title}`);
  } else {
    console.warn('Socket.IO instance not initialized. User notification skipped.');
  }
}

export function broadcastMilestoneCelebration(matchId: string, payload: any) {
  if (ioInstance) {
    ioInstance.to(`match:${matchId}`).emit('milestone_celebration', payload);
    ioInstance.emit('milestone_celebration', payload);
    console.log(`🎉 Broadcasted milestone_celebration for match:${matchId}:`, payload.type, payload.batsmanName);
  } else {
    console.warn('Socket.IO instance not initialized. Milestone broadcast skipped.');
  }
}
