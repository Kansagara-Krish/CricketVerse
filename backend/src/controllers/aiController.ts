import { Request, Response } from 'express';
import dotenv from 'dotenv';
import { AiConfigModel } from '../models/AiConfig';

dotenv.config();

const audioCache = new Map<string, string>(); // commentary text hash -> base64 audio or URL

export async function getAiConfig(req: Request, res: Response) {
  try {
    let config = await AiConfigModel.findOne({ id: 'global_ai_config' }).lean();

    if (!config) {
      const defaultApiKey = process.env.ELEVENLABS_API_KEY || '';
      const newConfig = await AiConfigModel.create({
        id: 'global_ai_config',
        apiKey: defaultApiKey,
        voiceId: 'JBFqnCBsd6RMkjVDRZzb',
        voiceName: 'George (Cricket Classic)',
        modelId: 'eleven_turbo_v2_5',
        stability: 0.5,
        similarityBoost: 0.8,
        style: 0.35,
        useSpeakerBoost: true,
        autoPlayVoice: true,
        commentaryStyle: 'Hype / Energetic',
        commentaryTrigger: 'Every Ball',
        isConfigured: defaultApiKey.trim().length > 0,
        updatedBy: 'System',
      });
      config = newConfig.toJSON();
    }

    return res.status(200).json(config);
  } catch (err) {
    console.error('Error fetching AI config:', err);
    return res.status(500).json({ error: 'Internal server error.' });
  }
}

export async function updateAiConfig(req: any, res: Response) {
  const {
    apiKey,
    voiceId,
    voiceName,
    modelId,
    stability,
    similarityBoost,
    style,
    useSpeakerBoost,
    autoPlayVoice,
    commentaryStyle,
    commentaryTrigger,
  } = req.body;

  try {
    const userRole = req.user?.role || 'Admin';
    const userName = req.user?.name || req.user?.email || 'Admin';

    const cleanApiKey = apiKey !== undefined ? String(apiKey).trim() : undefined;

    const updateDoc: any = {
      updatedBy: `${userName} (${userRole})`,
    };

    if (cleanApiKey !== undefined) {
      updateDoc.apiKey = cleanApiKey;
      updateDoc.isConfigured = cleanApiKey.length > 0;
    }
    if (voiceId !== undefined) updateDoc.voiceId = voiceId;
    if (voiceName !== undefined) updateDoc.voiceName = voiceName;
    if (modelId !== undefined) updateDoc.modelId = modelId;
    if (stability !== undefined) updateDoc.stability = Number(stability);
    if (similarityBoost !== undefined) updateDoc.similarityBoost = Number(similarityBoost);
    if (style !== undefined) updateDoc.style = Number(style);
    if (useSpeakerBoost !== undefined) updateDoc.useSpeakerBoost = Boolean(useSpeakerBoost);
    if (autoPlayVoice !== undefined) updateDoc.autoPlayVoice = Boolean(autoPlayVoice);
    if (commentaryStyle !== undefined) updateDoc.commentaryStyle = commentaryStyle;
    if (commentaryTrigger !== undefined) updateDoc.commentaryTrigger = commentaryTrigger;

    const config = await AiConfigModel.findOneAndUpdate(
      { id: 'global_ai_config' },
      { $set: updateDoc },
      { new: true, upsert: true }
    );

    // Clear audio cache on config change
    audioCache.clear();

    return res.status(200).json({
      message: 'ElevenLabs & AI configuration updated successfully.',
      config,
    });
  } catch (err) {
    console.error('Error updating AI config:', err);
    return res.status(500).json({ error: 'Internal server error.' });
  }
}

export async function testElevenLabsKey(req: Request, res: Response) {
  const { apiKey } = req.body;

  let keyToTest = apiKey ? String(apiKey).trim() : '';

  if (!keyToTest) {
    const config = await AiConfigModel.findOne({ id: 'global_ai_config' }).lean();
    keyToTest = config?.apiKey || process.env.ELEVENLABS_API_KEY || '';
  }

  if (!keyToTest) {
    return res.status(400).json({
      success: false,
      message: 'No ElevenLabs API key provided or found in database.',
    });
  }

  try {
    const response = await fetch('https://api.elevenlabs.io/v1/user/subscription', {
      method: 'GET',
      headers: {
        'xi-api-key': keyToTest,
      },
    });

    if (response.ok) {
      const data: any = await response.json();
      return res.status(200).json({
        success: true,
        message: `Connected! Tier: ${data.tier || 'Active'} (${data.character_count || 0} / ${data.character_limit || 0} chars used)`,
        data,
      });
    } else {
      let errorDetail = `Status ${response.status}`;
      try {
        const errJson: any = await response.json();
        if (errJson?.detail) errorDetail = typeof errJson.detail === 'string' ? errJson.detail : JSON.stringify(errJson.detail);
      } catch (_) {}

      return res.status(200).json({
        success: false,
        message: `ElevenLabs key validation failed: ${errorDetail}`,
      });
    }
  } catch (err: any) {
    console.error('Error testing ElevenLabs API key:', err);
    return res.status(500).json({
      success: false,
      message: `Network error connecting to ElevenLabs: ${err.message || err}`,
    });
  }
}

export async function generateCommentaryVoice(req: Request, res: Response) {
  const { text, voiceId, modelId } = req.body;

  if (!text) {
    return res.status(400).json({ error: 'Commentary text is required.' });
  }

  try {
    // 1. Fetch active ElevenLabs configuration from Database
    const dbConfig = await AiConfigModel.findOne({ id: 'global_ai_config' }).lean();
    const effectiveApiKey = dbConfig?.apiKey?.trim() || process.env.ELEVENLABS_API_KEY || '';
    const selectedVoiceId = voiceId || dbConfig?.voiceId || 'JBFqnCBsd6RMkjVDRZzb';
    const selectedModelId = modelId || dbConfig?.modelId || 'eleven_turbo_v2_5';
    const stability = dbConfig?.stability ?? 0.5;
    const similarityBoost = dbConfig?.similarityBoost ?? 0.8;
    const style = dbConfig?.style ?? 0.35;
    const useSpeakerBoost = dbConfig?.useSpeakerBoost ?? true;

    const cacheKey = `${selectedVoiceId}_${selectedModelId}_${text}`;
    if (audioCache.has(cacheKey)) {
      return res.status(200).json({
        audioBase64: audioCache.get(cacheKey),
        cached: true,
      });
    }

    if (!effectiveApiKey) {
      // Graceful fallback when API key is not yet set in database/environment
      return res.status(200).json({
        message: 'TTS key not configured in database. Fallback mode active.',
        text,
        audioBase64: null,
      });
    }

    const elevenLabsUrl = `https://api.elevenlabs.io/v1/text-to-speech/${selectedVoiceId}`;
    const response = await fetch(elevenLabsUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'xi-api-key': effectiveApiKey,
      },
      body: JSON.stringify({
        text,
        model_id: selectedModelId,
        voice_settings: {
          stability,
          similarity_boost: similarityBoost,
          style,
          use_speaker_boost: useSpeakerBoost,
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
