import Redis from 'ioredis';
import dotenv from 'dotenv';

dotenv.config();

const redisUrl = process.env.REDIS_URL || 'redis://localhost:6379';

let redis: Redis | null = null;

try {
  redis = new Redis(redisUrl, {
    maxRetriesPerRequest: 3,
    retryStrategy(times) {
      console.warn(`Redis connection retry attempt ${times}`);
      if (times > 3) {
        return null; // Stop retrying and fallback
      }
      return Math.min(times * 100, 2000);
    }
  });

  redis.on('connect', () => {
    console.log('Connected to Redis successfully.');
  });

  redis.on('error', (err) => {
    console.error('Redis error occurred:', err);
  });
} catch (err) {
  console.error('Failed to create Redis client:', err);
}

export { redis };

// Caching helper functions
export async function getCachedMatch(matchId: string): Promise<any | null> {
  if (!redis) return null;
  try {
    const data = await redis.get(`match:${matchId}:live`);
    return data ? JSON.parse(data) : null;
  } catch (err) {
    console.error('Redis getCachedMatch error:', err);
    return null;
  }
}

export async function setCachedMatch(matchId: string, matchData: any): Promise<void> {
  if (!redis) return;
  try {
    await redis.set(`match:${matchId}:live`, JSON.stringify(matchData), 'EX', 86400); // 24 hours TTL
  } catch (err) {
    console.error('Redis setCachedMatch error:', err);
  }
}

export async function invalidateCachedMatch(matchId: string): Promise<void> {
  if (!redis) return;
  try {
    await redis.del(`match:${matchId}:live`);
    await redis.del(`match:${matchId}:balls`);
  } catch (err) {
    console.error('Redis invalidateCachedMatch error:', err);
  }
}
