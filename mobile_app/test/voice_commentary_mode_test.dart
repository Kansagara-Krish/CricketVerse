import 'package:flutter_test/flutter_test.dart';
import 'package:cricketverse_ai/services/elevenlabs_service.dart';

void main() {
  group('Voice Commentary Dual Mode Tests (ElevenLabs vs Inbuilt TTS)', () {
    test('Default mode should be inbuilt_tts with 0 tokens', () {
      final settings = ElevenLabsSettings();
      expect(settings.voiceProvider, 'inbuilt_tts');
      expect(settings.isInbuiltTts, isTrue);
      expect(settings.isElevenLabs, isFalse);
      expect(settings.ttsSpeechRate, 0.5);
      expect(settings.ttsPitch, 1.0);
      expect(settings.ttsLanguage, 'en-US');
      expect(settings.activeVoiceDisplayName, 'Inbuilt Text-to-Speech (Free)');
    });

    test('ElevenLabs mode configuration and getters', () {
      final settings = ElevenLabsSettings(
        voiceProvider: 'elevenlabs',
        apiKey: 'test_key_123',
        voiceName: 'Adam (Stadium Hype)',
        voiceId: 'pNInz6obpgDQGcFmaJgB',
      );

      expect(settings.voiceProvider, 'elevenlabs');
      expect(settings.isElevenLabs, isTrue);
      expect(settings.isInbuiltTts, isFalse);
      expect(settings.activeVoiceDisplayName, 'Adam (Stadium Hype)');
    });

    test('JSON Serialization and Deserialization with Inbuilt TTS', () {
      final original = ElevenLabsSettings(
        voiceProvider: 'inbuilt_tts',
        ttsSpeechRate: 0.55,
        ttsPitch: 1.10,
        ttsLanguage: 'en-GB',
      );

      final jsonMap = original.toJson();
      expect(jsonMap['voiceProvider'], 'inbuilt_tts');
      expect(jsonMap['ttsSpeechRate'], 0.55);
      expect(jsonMap['ttsPitch'], 1.10);
      expect(jsonMap['ttsLanguage'], 'en-GB');

      final restored = ElevenLabsSettings.fromJson(jsonMap);
      expect(restored.voiceProvider, 'inbuilt_tts');
      expect(restored.isInbuiltTts, isTrue);
      expect(restored.isElevenLabs, isFalse);
      expect(restored.ttsSpeechRate, 0.55);
      expect(restored.ttsPitch, 1.10);
      expect(restored.ttsLanguage, 'en-GB');
    });

    test('JSON Serialization and Deserialization with ElevenLabs mode', () {
      final original = ElevenLabsSettings(
        voiceProvider: 'elevenlabs',
        apiKey: 'sk_live_samplekey',
        voiceName: 'George (Cricket Classic)',
        voiceId: 'JBFqnCBsd6RMkjVDRZzb',
        modelId: 'eleven_turbo_v2_5',
      );

      final jsonMap = original.toJson();
      expect(jsonMap['voiceProvider'], 'elevenlabs');
      expect(jsonMap['apiKey'], 'sk_live_samplekey');

      final restored = ElevenLabsSettings.fromJson(jsonMap);
      expect(restored.voiceProvider, 'elevenlabs');
      expect(restored.isElevenLabs, isTrue);
      expect(restored.isInbuiltTts, isFalse);
      expect(restored.apiKey, 'sk_live_samplekey');
      expect(restored.activeVoiceDisplayName, 'George (Cricket Classic)');
    });

    test('Backward compatibility: Inferred mode from older payloads', () {
      // Legacy JSON with API key -> should default to elevenlabs
      final legacyWithKey = {
        'apiKey': 'legacy_key_xyz',
        'voiceName': 'Rachel (Clear & Analytical)',
      };
      final fromLegacy1 = ElevenLabsSettings.fromJson(legacyWithKey);
      expect(fromLegacy1.voiceProvider, 'elevenlabs');
      expect(fromLegacy1.isElevenLabs, isTrue);

      // Legacy JSON without API key -> should default to inbuilt_tts
      final legacyWithoutKey = {
        'apiKey': '',
        'voiceName': 'George (Cricket Classic)',
      };
      final fromLegacy2 = ElevenLabsSettings.fromJson(legacyWithoutKey);
      expect(fromLegacy2.voiceProvider, 'inbuilt_tts');
      expect(fromLegacy2.isInbuiltTts, isTrue);
    });

    test('Available languages map verification', () {
      expect(ElevenLabsService.availableLanguages.containsKey('en-US'), isTrue);
      expect(ElevenLabsService.availableLanguages.containsKey('en-GB'), isTrue);
      expect(ElevenLabsService.availableLanguages.containsKey('en-IN'), isTrue);
      expect(ElevenLabsService.availableLanguages.containsKey('en-AU'), isTrue);
    });
  });
}
