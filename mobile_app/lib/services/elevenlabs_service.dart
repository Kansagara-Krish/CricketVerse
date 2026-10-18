import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class ElevenLabsVoicePreset {
  final String id;
  final String name;
  final String description;
  final String sampleGender;

  const ElevenLabsVoicePreset({
    required this.id,
    required this.name,
    required this.description,
    required this.sampleGender,
  });
}

class ElevenLabsSettings {
  String voiceProvider; // 'elevenlabs' | 'inbuilt_tts'
  String apiKey;
  String voiceId;
  String voiceName;
  String modelId;
  double stability;
  double similarityBoost;
  double style;
  bool useSpeakerBoost;
  bool autoPlayVoice;
  String commentaryStyle; // 'Hype / Energetic', 'Professional', 'Technical', 'Casual'
  String commentaryTrigger; // 'Every Ball', 'Boundaries & Wickets', 'Over Finish'
  double ttsSpeechRate; // 0.3 to 1.0, default 0.5
  double ttsPitch; // 0.5 to 1.5, default 1.0
  String ttsLanguage; // 'en-US', 'en-GB', 'en-IN', 'en-AU'

  ElevenLabsSettings({
    this.voiceProvider = 'inbuilt_tts',
    this.apiKey = '',
    this.voiceId = 'JBFqnCBsd6RMkjVDRZzb', // George - British Narrator
    this.voiceName = 'George (Cricket Classic)',
    this.modelId = 'eleven_turbo_v2_5',
    this.stability = 0.5,
    this.similarityBoost = 0.8,
    this.style = 0.35,
    this.useSpeakerBoost = true,
    this.autoPlayVoice = true,
    this.commentaryStyle = 'Hype / Energetic',
    this.commentaryTrigger = 'Every Ball',
    this.ttsSpeechRate = 0.5,
    this.ttsPitch = 1.0,
    this.ttsLanguage = 'en-US',
  });

  bool get isElevenLabs => voiceProvider == 'elevenlabs';
  bool get isInbuiltTts => voiceProvider == 'inbuilt_tts';
  String get activeVoiceDisplayName =>
      isInbuiltTts ? 'Inbuilt Text-to-Speech (Free)' : voiceName;

  Map<String, dynamic> toJson() => {
        'voiceProvider': voiceProvider,
        'apiKey': apiKey,
        'voiceId': voiceId,
        'voiceName': voiceName,
        'modelId': modelId,
        'stability': stability,
        'similarityBoost': similarityBoost,
        'style': style,
        'useSpeakerBoost': useSpeakerBoost,
        'autoPlayVoice': autoPlayVoice,
        'commentaryStyle': commentaryStyle,
        'commentaryTrigger': commentaryTrigger,
        'ttsSpeechRate': ttsSpeechRate,
        'ttsPitch': ttsPitch,
        'ttsLanguage': ttsLanguage,
      };

  factory ElevenLabsSettings.fromJson(Map<String, dynamic> json) {
    String provider = json['voiceProvider'] ?? '';
    final apiKeyStr = json['apiKey']?.toString().trim() ?? '';
    if (provider.isEmpty) {
      provider = apiKeyStr.isNotEmpty ? 'elevenlabs' : 'inbuilt_tts';
    }

    return ElevenLabsSettings(
      voiceProvider: provider,
      apiKey: apiKeyStr,
      voiceId: json['voiceId'] ?? 'JBFqnCBsd6RMkjVDRZzb',
      voiceName: json['voiceName'] ?? 'George (Cricket Classic)',
      modelId: json['modelId'] ?? 'eleven_turbo_v2_5',
      stability: (json['stability'] as num?)?.toDouble() ?? 0.5,
      similarityBoost: (json['similarityBoost'] as num?)?.toDouble() ?? 0.8,
      style: (json['style'] as num?)?.toDouble() ?? 0.35,
      useSpeakerBoost: json['useSpeakerBoost'] ?? true,
      autoPlayVoice: json['autoPlayVoice'] ?? false,
      commentaryStyle: json['commentaryStyle'] ?? 'Hype / Energetic',
      commentaryTrigger: json['commentaryTrigger'] ?? 'Every Ball',
      ttsSpeechRate: (json['ttsSpeechRate'] as num?)?.toDouble() ?? 0.5,
      ttsPitch: (json['ttsPitch'] as num?)?.toDouble() ?? 1.0,
      ttsLanguage: json['ttsLanguage'] ?? 'en-US',
    );
  }
}

class ElevenLabsService {
  static final ElevenLabsService _instance = ElevenLabsService._internal();
  factory ElevenLabsService() => _instance;
  ElevenLabsService._internal();

  static const List<ElevenLabsVoicePreset> defaultVoices = [
    ElevenLabsVoicePreset(
      id: 'JBFqnCBsd6RMkjVDRZzb',
      name: 'George (Cricket Classic)',
      description: 'Warm, articulate, classic British cricket broadcaster tone.',
      sampleGender: 'Male',
    ),
    ElevenLabsVoicePreset(
      id: 'pNInz6obpgDQGcFmaJgB',
      name: 'Adam (Stadium Hype)',
      description: 'Dominant, high-energy, exciting stadium announcer style.',
      sampleGender: 'Male',
    ),
    ElevenLabsVoicePreset(
      id: 'TxGEqnHWrfWFTfGW9XjX',
      name: 'Josh (Deep & Punchy)',
      description: 'Deep, resonant, dramatic cricket highlights narrator.',
      sampleGender: 'Male',
    ),
    ElevenLabsVoicePreset(
      id: '21m00Tcm4TlvDq8ikWAM',
      name: 'Rachel (Clear & Analytical)',
      description: 'Calm, authoritative, tactical pitch analysis voice.',
      sampleGender: 'Female',
    ),
    ElevenLabsVoicePreset(
      id: 'ErXwobaYiN019PkySvjV',
      name: 'Antoni (Dynamic & Bold)',
      description: 'Passionate, lively, fast-paced commentary voice.',
      sampleGender: 'Male',
    ),
    ElevenLabsVoicePreset(
      id: 'IKne3meq5aSn9XLyUdCD',
      name: 'Charlie (Casual Australian)',
      description: 'Relaxed, authentic, friendly match companion voice.',
      sampleGender: 'Male',
    ),
  ];

  static const List<String> availableModels = [
    'eleven_turbo_v2_5',
    'eleven_multilingual_v2',
    'eleven_monolingual_v1',
  ];

  ElevenLabsSettings _settings = ElevenLabsSettings();
  ElevenLabsSettings get settings => _settings;

  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts _fallbackTts = FlutterTts();
  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  final ValueNotifier<bool> isPlayingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String?> currentPlayingTextNotifier = ValueNotifier<String?>(null);

  bool _isTtsInitialized = false;

  Future<void> init() async {
    await loadSettings();
    _initAudioListeners();
    await _initFallbackTts();
  }

  void _initAudioListeners() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      _isPlaying = (state == PlayerState.playing);
      isPlayingNotifier.value = _isPlaying;
      if (state == PlayerState.completed || state == PlayerState.stopped) {
        currentPlayingTextNotifier.value = null;
      }
    });
  }

  static const Map<String, String> availableLanguages = {
    'en-US': 'English (US Broadcaster)',
    'en-GB': 'English (UK / Cricket Classic)',
    'en-IN': 'English (India Stadium)',
    'en-AU': 'English (Australia Companion)',
  };

  Future<void> _initFallbackTts() async {
    try {
      await _fallbackTts.setLanguage(_settings.ttsLanguage);
      await _fallbackTts.setSpeechRate(_settings.ttsSpeechRate);
      await _fallbackTts.setVolume(1.0);
      await _fallbackTts.setPitch(_settings.ttsPitch);
      _fallbackTts.setCompletionHandler(() {
        _isPlaying = false;
        isPlayingNotifier.value = false;
        currentPlayingTextNotifier.value = null;
      });
      _fallbackTts.setErrorHandler((dynamic msg) {
        _isPlaying = false;
        isPlayingNotifier.value = false;
        currentPlayingTextNotifier.value = null;
      });
      _isTtsInitialized = true;
    } catch (e) {
      debugPrint('Error initializing inbuilt TTS: $e');
    }
  }

  Future<ElevenLabsSettings> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('cricketverse_elevenlabs_settings_v1');
      if (jsonStr != null) {
        final decoded = jsonDecode(jsonStr);
        _settings = ElevenLabsSettings.fromJson(decoded);
      }

      // Fetch centralized config from backend database
      try {
        final remoteConfig = await ApiService.getAiConfig();
        if (remoteConfig != null) {
          _settings = ElevenLabsSettings.fromJson(remoteConfig);
          await prefs.setString(
            'cricketverse_elevenlabs_settings_v1',
            jsonEncode(_settings.toJson()),
          );
        }
      } catch (remoteErr) {
        debugPrint('Could not sync remote ElevenLabs config: $remoteErr');
      }

      // Sync active TTS properties
      if (_isTtsInitialized) {
        await _fallbackTts.setLanguage(_settings.ttsLanguage);
        await _fallbackTts.setSpeechRate(_settings.ttsSpeechRate);
        await _fallbackTts.setPitch(_settings.ttsPitch);
      }
    } catch (e) {
      debugPrint('Error loading ElevenLabs settings: $e');
    }
    return _settings;
  }

  Future<bool> saveSettings(ElevenLabsSettings newSettings) async {
    try {
      _settings = newSettings;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'cricketverse_elevenlabs_settings_v1',
        jsonEncode(_settings.toJson()),
      );

      // Reapply TTS voice settings
      if (_isTtsInitialized) {
        await _fallbackTts.setLanguage(_settings.ttsLanguage);
        await _fallbackTts.setSpeechRate(_settings.ttsSpeechRate);
        await _fallbackTts.setPitch(_settings.ttsPitch);
      }

      // Persist to centralized backend database
      try {
        await ApiService.updateAiConfig(_settings.toJson());
      } catch (remoteErr) {
        debugPrint('Could not persist ElevenLabs config to database: $remoteErr');
      }

      return true;
    } catch (e) {
      debugPrint('Error saving ElevenLabs settings: $e');
      return false;
    }
  }

  /// Verify ElevenLabs API Key
  Future<Map<String, dynamic>> testConnection(String apiKey) async {
    if (apiKey.trim().isEmpty) {
      return {
        'success': false,
        'message': 'API Key cannot be empty. Please enter your ElevenLabs API Key.',
      };
    }

    try {
      // First try via backend centralized validator
      final serverRes = await ApiService.testElevenLabsKey(apiKey);
      if (serverRes['success'] == true) {
        return serverRes;
      }

      // Direct fallback
      final res = await http.get(
        Uri.parse('https://api.elevenlabs.io/v1/user/subscription'),
        headers: {
          'xi-api-key': apiKey.trim(),
        },
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final tier = data['tier'] ?? 'Free';
        final charCount = data['character_count'] ?? 0;
        final charLimit = data['character_limit'] ?? 0;
        return {
          'success': true,
          'message': 'Connected! Tier: $tier ($charCount / $charLimit chars used)',
          'data': data,
        };
      } else {
        String errorDetail = 'Status ${res.statusCode}';
        try {
          final errBody = jsonDecode(res.body);
          if (errBody['detail'] != null) {
            errorDetail = errBody['detail'].toString();
          }
        } catch (_) {}
        return {
          'success': false,
          'message': serverRes['message'] ?? 'Connection failed: $errorDetail',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error reaching ElevenLabs: $e',
      };
    }
  }

  /// Speak commentary using the configured engine:
  /// Mode 1 (ElevenLabs): Uses ElevenLabs API (requires API key, cloud neural voice).
  /// Mode 2 (Inbuilt TTS): Uses native device text-to-speech (100% free, zero tokens, no API key).
  Future<bool> speakCommentary(
    String text, {
    VoidCallback? onStart,
    VoidCallback? onComplete,
    Function(String error)? onError,
  }) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return false;

    // Stop any current audio
    await stopAudio();

    _isPlaying = true;
    isPlayingNotifier.value = true;
    currentPlayingTextNotifier.value = cleanText;
    onStart?.call();

    // OPTION 2: INBUILT TEXT-TO-SPEECH (Zero API tokens, 100% free, local device engine)
    if (_settings.isInbuiltTts) {
      return await _speakWithInbuiltTts(
        cleanText,
        onComplete: onComplete,
        onError: onError,
      );
    }

    // OPTION 1: ELEVENLABS API (Requires valid API key & token usage)
    if (_settings.apiKey.trim().isNotEmpty) {
      try {
        final audioBytes = await _fetchElevenLabsAudio(cleanText);
        if (audioBytes != null && audioBytes.isNotEmpty) {
          if (!kIsWeb) {
            final tempDir = await getTemporaryDirectory();
            final hash = cleanText.hashCode.abs();
            final file = File('${tempDir.path}/commentary_$hash.mp3');
            await file.writeAsBytes(audioBytes);

            await _audioPlayer.play(DeviceFileSource(file.path));
          } else {
            await _audioPlayer.play(BytesSource(audioBytes));
          }

          _audioPlayer.onPlayerComplete.first.then((_) {
            _isPlaying = false;
            isPlayingNotifier.value = false;
            currentPlayingTextNotifier.value = null;
            onComplete?.call();
          });

          return true;
        }
      } catch (e) {
        debugPrint('ElevenLabs API request failed ($e), falling back to Inbuilt TTS.');
      }
    } else {
      debugPrint('ElevenLabs engine chosen but API key is missing. Using Inbuilt TTS fallback.');
    }

    // Graceful fallback to Inbuilt TTS if ElevenLabs fails or is unconfigured
    return await _speakWithInbuiltTts(
      cleanText,
      onComplete: onComplete,
      onError: onError,
    );
  }

  /// Internal playback via native device Text-to-Speech
  Future<bool> _speakWithInbuiltTts(
    String cleanText, {
    VoidCallback? onComplete,
    Function(String error)? onError,
  }) async {
    try {
      await _initFallbackTts();
      await _fallbackTts.setLanguage(_settings.ttsLanguage);
      await _fallbackTts.setSpeechRate(_settings.ttsSpeechRate);
      await _fallbackTts.setPitch(_settings.ttsPitch);

      _fallbackTts.setCompletionHandler(() {
        _isPlaying = false;
        isPlayingNotifier.value = false;
        currentPlayingTextNotifier.value = null;
        onComplete?.call();
      });

      _fallbackTts.setErrorHandler((dynamic err) {
        _isPlaying = false;
        isPlayingNotifier.value = false;
        currentPlayingTextNotifier.value = null;
        onError?.call('Inbuilt TTS playback error: $err');
      });

      await _fallbackTts.speak(cleanText);
      return true;
    } catch (e) {
      _isPlaying = false;
      isPlayingNotifier.value = false;
      currentPlayingTextNotifier.value = null;
      onError?.call('Inbuilt TTS playback failed: $e');
      return false;
    }
  }

  /// Explicitly speak using Inbuilt TTS (for live preview in Admin AI Settings)
  Future<bool> speakWithInbuiltTts(
    String text, {
    VoidCallback? onComplete,
    Function(String error)? onError,
  }) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return false;

    await stopAudio();
    _isPlaying = true;
    isPlayingNotifier.value = true;
    currentPlayingTextNotifier.value = cleanText;

    return await _speakWithInbuiltTts(
      cleanText,
      onComplete: onComplete,
      onError: onError,
    );
  }

  /// Explicitly speak using ElevenLabs API (for live preview in Admin AI Settings)
  Future<bool> speakWithElevenLabs(
    String text, {
    VoidCallback? onComplete,
    Function(String error)? onError,
  }) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return false;

    await stopAudio();
    _isPlaying = true;
    isPlayingNotifier.value = true;
    currentPlayingTextNotifier.value = cleanText;

    if (_settings.apiKey.trim().isEmpty) {
      _isPlaying = false;
      isPlayingNotifier.value = false;
      currentPlayingTextNotifier.value = null;
      onError?.call('Please enter an ElevenLabs API Key first.');
      return false;
    }

    try {
      final audioBytes = await _fetchElevenLabsAudio(cleanText);
      if (audioBytes != null && audioBytes.isNotEmpty) {
        if (!kIsWeb) {
          final tempDir = await getTemporaryDirectory();
          final hash = cleanText.hashCode.abs();
          final file = File('${tempDir.path}/commentary_$hash.mp3');
          await file.writeAsBytes(audioBytes);
          await _audioPlayer.play(DeviceFileSource(file.path));
        } else {
          await _audioPlayer.play(BytesSource(audioBytes));
        }

        _audioPlayer.onPlayerComplete.first.then((_) {
          _isPlaying = false;
          isPlayingNotifier.value = false;
          currentPlayingTextNotifier.value = null;
          onComplete?.call();
        });

        return true;
      } else {
        _isPlaying = false;
        isPlayingNotifier.value = false;
        currentPlayingTextNotifier.value = null;
        onError?.call('ElevenLabs synthesis failed. Check key validity and character quota.');
        return false;
      }
    } catch (e) {
      _isPlaying = false;
      isPlayingNotifier.value = false;
      currentPlayingTextNotifier.value = null;
      onError?.call('Network error reaching ElevenLabs: $e');
      return false;
    }
  }

  Future<Uint8List?> _fetchElevenLabsAudio(String text) async {
    final voiceId = _settings.voiceId.isNotEmpty
        ? _settings.voiceId
        : 'JBFqnCBsd6RMkjVDRZzb';
    final url = Uri.parse('https://api.elevenlabs.io/v1/text-to-speech/$voiceId');

    final body = jsonEncode({
      'text': text,
      'model_id': _settings.modelId,
      'voice_settings': {
        'stability': _settings.stability,
        'similarity_boost': _settings.similarityBoost,
        'style': _settings.style,
        'use_speaker_boost': _settings.useSpeakerBoost,
      }
    });

    final res = await http.post(
      url,
      headers: {
        'xi-api-key': _settings.apiKey.trim(),
        'Content-Type': 'application/json',
        'Accept': 'audio/mpeg',
      },
      body: body,
    ).timeout(const Duration(seconds: 15));

    if (res.statusCode == 200) {
      return res.bodyBytes;
    } else {
      debugPrint('ElevenLabs returned HTTP ${res.statusCode}: ${res.body}');
      return null;
    }
  }

  Future<void> stopAudio() async {
    try {
      await _audioPlayer.stop();
      await _fallbackTts.stop();
    } catch (_) {}
    _isPlaying = false;
    isPlayingNotifier.value = false;
    currentPlayingTextNotifier.value = null;
  }
}
