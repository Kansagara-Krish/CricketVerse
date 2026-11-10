import Redis from 'ioredis';
import dotenv from 'dotenv';

dotenv.config();

const redisUrl = process.env.REDIS_URL;

let redis: Redis | null = null;

if (redisUrl) {
  try {
    let cleanUrl = redisUrl.trim();
    if (cleanUrl.startsWith('"') && cleanUrl.endsWith('"')) {
      cleanUrl = cleanUrl.slice(1, -1);
    }
    if (cleanUrl.startsWith('redis://') && cleanUrl.includes('upstash.io')) {
      cleanUrl = cleanUrl.replace('redis://', 'rediss://');
    }

    redis = new Redis(cleanUrl, {
      maxRetriesPerRequest: null,
      connectTimeout: 10000,
      retryStrategy(times) {
        if (times > 5) {
          console.warn('Redis disconnected or timed out. Operating with memory cache.');
          return null; // Stop retrying and fallback
        }
        return Math.min(times * 1000, 3000);
      }
    });

    redis.on('connect', () => {
      console.log('Connected to Redis successfully.');
    });

    redis.on('error', (err) => {
      console.warn('Redis notice:', err.message);
    });
  } catch (err) {
    console.warn('Failed to create Redis client:', err);
    redis = null;
  }
} else {
  console.log('REDIS_URL environment variable is not set. Gracefully running without Redis caching / scaling.');
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
