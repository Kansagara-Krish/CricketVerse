import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  ElevenLabsSettings({
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
  });

  Map<String, dynamic> toJson() => {
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
      };

  factory ElevenLabsSettings.fromJson(Map<String, dynamic> json) =>
      ElevenLabsSettings(
        apiKey: json['apiKey'] ?? '',
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
      );
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

  Future<void> _initFallbackTts() async {
    if (_isTtsInitialized) return;
    try {
      await _fallbackTts.setLanguage("en-US");
      await _fallbackTts.setSpeechRate(0.5);
      await _fallbackTts.setVolume(1.0);
      await _fallbackTts.setPitch(1.0);
      _fallbackTts.setCompletionHandler(() {
        _isPlaying = false;
        isPlayingNotifier.value = false;
        currentPlayingTextNotifier.value = null;
      });
      _isTtsInitialized = true;
    } catch (e) {
      debugPrint('Error initializing fallback TTS: $e');
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
          'message': 'Connection failed: $errorDetail',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error reaching ElevenLabs: $e',
      };
    }
  }

  /// Speak commentary using ElevenLabs TTS with fallback to flutter_tts
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

    // If API Key is present, try ElevenLabs REST API
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
        debugPrint('ElevenLabs API request failed ($e), using fallback TTS.');
      }
    }

    // Fallback: flutter_tts
    try {
      await _initFallbackTts();
      await _fallbackTts.speak(cleanText);
      _fallbackTts.setCompletionHandler(() {
        _isPlaying = false;
        isPlayingNotifier.value = false;
        currentPlayingTextNotifier.value = null;
        onComplete?.call();
      });
      return true;
    } catch (e) {
      _isPlaying = false;
      isPlayingNotifier.value = false;
      currentPlayingTextNotifier.value = null;
      onError?.call('Audio playback failed: $e');
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
