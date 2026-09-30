import { Request, Response } from 'express';
import dotenv from 'dotenv';

dotenv.config();

const ELEVENLABS_API_KEY = process.env.ELEVENLABS_API_KEY;
const audioCache = new Map<string, string>(); // commentary text hash -> base64 audio or URL

export async function generateCommentaryVoice(req: Request, res: Response) {
  const { text, voiceId } = req.body;

  if (!text) {
    return res.status(400).json({ error: 'Commentary text is required.' });
  }

  const selectedVoiceId = voiceId || '21m00Tcm4TlvDq8ikWAM'; // Default ElevenLabs voice (Rachel)

  try {
    const cacheKey = `${selectedVoiceId}_${text}`;
    if (audioCache.has(cacheKey)) {
      return res.status(200).json({
        audioBase64: audioCache.get(cacheKey),
        cached: true,
      });
    }

    if (!ELEVENLABS_API_KEY) {
      // Graceful fallback when API key is not yet set in environment
      return res.status(200).json({
        message: 'TTS key not configured. Fallback mode active.',
        text,
        audioBase64: null,
      });
    }

    const elevenLabsUrl = `https://api.elevenlabs.io/v1/text-to-speech/${selectedVoiceId}`;
    const response = await fetch(elevenLabsUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'xi-api-key': ELEVENLABS_API_KEY,
      },
      body: JSON.stringify({
        text,
        model_id: 'eleven_monolingual_v1',
        voice_settings: {
          stability: 0.75,
          similarity_boost: 0.75,
        },
      }),
    });

    if (!response.ok) {
      console.warn(`ElevenLabs API returned status ${response.status}`);
      return res.status(200).json({
        message: 'TTS generation unavailable.',
        text,
        audioBase64: null,
      });
    }

    const arrayBuffer = await response.arrayBuffer();
    const base64 = Buffer.from(arrayBuffer).toString('base64');
    audioCache.set(cacheKey, base64);

    return res.status(200).json({
      audioBase64: base64,
      cached: false,
    });
  } catch (err) {
    console.error('Error generating commentary voice:', err);
    return res.status(500).json({ error: 'Internal server error while processing voice commentary.' });
  }
}

export async function generateCustomCommentary(req: Request, res: Response) {
  const { batsman, bowler, runs, isWicket, wicketType, extraType, situation } = req.body;

  try {
    let commentary = `${bowler || 'Bowler'} delivers to ${batsman || 'Batsman'}. `;
    if (isWicket) {
      commentary += `OUT! ${wicketType || 'Wicket'}! Crucial breakthrough!`;
    } else if (runs === 6) {
      commentary += `SIX! Smashed high and handsome over the boundary rope!`;
    } else if (runs === 4) {
      commentary += `FOUR! Pure placement and elegance to find the fence!`;
    } else if (runs === 0) {
      commentary += `Dot ball, neatly defended.`;
    } else {
      commentary += `${runs} runs taken.`;
    }

    if (situation) {
      commentary += ` ${situation}`;
    }

    return res.status(200).json({ commentary });
  } catch (err) {
    console.error('Error generating custom commentary:', err);
    return res.status(500).json({ error: 'Internal server error.' });
  }
}
