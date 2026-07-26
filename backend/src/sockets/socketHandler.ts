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
    const pubClient = redis;
    const subClient = redis.duplicate();
    io.adapter(createAdapter(pubClient, subClient));
    console.log('Socket.IO Redis adapter enabled.');
  }

  io.on('connection', (socket: Socket) => {
    console.log(`Socket connected: ${socket.id}`);

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

    socket.on('disconnect', () => {
      console.log(`Socket disconnected: ${socket.id}`);
    });
  });

  ioInstance = io;
  return io;
}

export function broadcastMatchUpdate(matchId: string, eventName: string, payload: any) {
  if (ioInstance) {
    ioInstance.to(`match:${matchId}`).emit(eventName, payload);
    console.log(`Broadcasted event ${eventName} to room match:${matchId}`);
  } else {
    console.warn('Socket.IO instance not initialized. Broadcast skipped.');
  }
}
