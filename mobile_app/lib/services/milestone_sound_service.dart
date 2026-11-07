import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MilestoneSoundService {
  static final MilestoneSoundService _instance = MilestoneSoundService._internal();
  factory MilestoneSoundService() => _instance;
  MilestoneSoundService._internal();

  AudioPlayer? _player;
  bool _isSoundEnabled = true;
  bool _isInitialized = false;
  bool _isPlaying = false;
  StreamSubscription? _playerCompleteSub;

  bool get isSoundEnabled => _isSoundEnabled;
  bool get isPlaying => _isPlaying;

  Uint8List? _cached50SoundBytes;
  Uint8List? _cached100SoundBytes;
  Uint8List? _cachedWicketSoundBytes;
  Uint8List? _cachedSixSoundBytes;
  Uint8List? _cached5WSoundBytes;
  Uint8List? _cachedMatchWonSoundBytes;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _isSoundEnabled = prefs.getBool('cricketverse_celebration_sound') ?? true;
      try {
        _player = AudioPlayer();
      } catch (e) {
        debugPrint('AudioPlayer init channel warning: $e');
      }
      _isInitialized = true;
    } catch (e) {
      debugPrint('MilestoneSoundService init error: $e');
    }
  }

  Future<void> toggleSound() async {
    _isSoundEnabled = !_isSoundEnabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('cricketverse_celebration_sound', _isSoundEnabled);
    } catch (_) {}
  }

  Future<void> playCelebrationSound(String type, {VoidCallback? onComplete}) async {
    if (!_isSoundEnabled) {
      onComplete?.call();
      return;
    }

    try {
      _player ??= AudioPlayer();

      // Central audio-focus: stop previous celebration sound safely before new one
      await _playerCompleteSub?.cancel();
      _playerCompleteSub = null;
      await _player?.stop();
      _isPlaying = true;

      final Uint8List bytes = getSoundBytesFor(type);

      _playerCompleteSub = _player?.onPlayerComplete.listen((_) {
        _isPlaying = false;
        _playerCompleteSub?.cancel();
        _playerCompleteSub = null;
        onComplete?.call();
      });

      await _player?.play(BytesSource(bytes)).timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          debugPrint('Audio playback timeout safeguard reached');
        },
      );
    } catch (e) {
      debugPrint('Error playing celebration sound ($type): $e');
      _isPlaying = false;
      onComplete?.call();
    }
  }

  Future<void> stop() async {
    try {
      await _playerCompleteSub?.cancel();
      _playerCompleteSub = null;
      await _player?.stop();
      _isPlaying = false;
    } catch (_) {}
  }

  void dispose() {
    _playerCompleteSub?.cancel();
    _playerCompleteSub = null;
    _player?.dispose();
    _player = null;
    _isPlaying = false;
  }

  Uint8List getSoundBytesFor(String type) {
    final normalizedType = type.trim().toUpperCase();
    if (normalizedType == '100') return _getOrGenerate100Sound();
    if (normalizedType == '50') return _getOrGenerate50Sound();
    if (normalizedType == 'WICKET') return _getOrGenerateWicketSound();
    if (normalizedType == 'SIX') return _getOrGenerateSixSound();
    if (normalizedType == 'FIVE_WICKET' || normalizedType == '5W') return _getOrGenerate5WSound();
    if (normalizedType == 'MATCH_WON' || normalizedType == 'MATCH_WIN') return _getOrGenerateMatchWonSound();
    return _getOrGenerate50Sound();
  }

  Uint8List _getOrGenerate50Sound() {
    return _cached50SoundBytes ??= _synthesizeFanfareWithCrowd(
      durationSec: 2.8,
      fanfareFreqs: [523.25, 659.25, 783.99, 1046.50], // C5, E5, G5, C6
      crowdIntensity: 0.40,
      applauseRate: 0.06,
      brassSheen: true,
      randomSeed: 50,
    );
  }

  Uint8List _getOrGenerate100Sound() {
    return _cached100SoundBytes ??= _synthesizeFanfareWithCrowd(
      durationSec: 4.8,
      fanfareFreqs: [261.63, 392.00, 523.25, 659.25, 783.99, 1046.50], // C4, G4, C5, E5, G5, C6
      crowdIntensity: 0.55,
      applauseRate: 0.10,
      brassSheen: true,
      randomSeed: 100,
    );
  }

  Uint8List _getOrGenerateSixSound() {
    return _cachedSixSoundBytes ??= _synthesizeImpactWithCrowd(
      durationSec: 1.8,
      impactFreq: 1400.0,
      impactDurationSec: 0.05,
      crowdSurgeDelay: 0.04,
      crowdIntensity: 0.60,
      randomSeed: 6,
    );
  }

  Uint8List _getOrGenerateWicketSound() {
    return _cachedWicketSoundBytes ??= _synthesizeImpactWithCrowd(
      durationSec: 2.6,
      impactFreq: 280.0,
      secondaryFreq: 1100.0,
      impactDurationSec: 0.08,
      crowdSurgeDelay: 0.06,
      crowdIntensity: 0.65,
      randomSeed: 99,
    );
  }

  Uint8List _getOrGenerate5WSound() {
    return _cached5WSoundBytes ??= _synthesizeFanfareWithCrowd(
      durationSec: 3.5,
      fanfareFreqs: [293.66, 369.99, 440.00, 587.33, 739.99, 880.00], // D4, F#4, A4, D5, F#5, A5
      crowdIntensity: 0.50,
      applauseRate: 0.09,
      brassSheen: true,
      randomSeed: 55,
    );
  }

  Uint8List _getOrGenerateMatchWonSound() {
    return _cachedMatchWonSoundBytes ??= _synthesizeFanfareWithCrowd(
      durationSec: 5.5,
      fanfareFreqs: [196.00, 261.63, 329.63, 392.00, 523.25, 659.25, 783.99, 1046.50], // Grand G3 - C6
      crowdIntensity: 0.65,
      applauseRate: 0.12,
      brassSheen: true,
      randomSeed: 777,
    );
  }

  /// Synthesizes celebratory fanfare melody + stadium applause into 16-bit mono PCM WAV
  Uint8List _synthesizeFanfareWithCrowd({
    required double durationSec,
    required List<double> fanfareFreqs,
    required double crowdIntensity,
    required double applauseRate,
    required bool brassSheen,
    required int randomSeed,
  }) {
    const sampleRate = 22050;
    final totalSamples = (sampleRate * durationSec).toInt();
    final pcmData = Int16List(totalSamples);
    final random = math.Random(randomSeed);

    double crowdFilterPrev = 0.0;

    for (int i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;

      // 1. Crowd envelope
      double crowdEnv;
      if (t < 0.25) {
        crowdEnv = t / 0.25;
      } else if (t < durationSec - 0.7) {
        crowdEnv = 1.0;
      } else {
        crowdEnv = math.max(0.0, (durationSec - t) / 0.7);
      }

      // Filtered white noise for crowd wash
      final whiteNoise = (random.nextDouble() * 2.0 - 1.0);
      crowdFilterPrev = crowdFilterPrev * 0.82 + whiteNoise * 0.18;

      // Stochastic clapping impulses
      double clap = 0.0;
      if (random.nextDouble() < applauseRate) {
        clap = (random.nextDouble() * 2.0 - 1.0) * 0.45;
      }

      final crowdSample = (crowdFilterPrev * 0.7 + clap) * crowdEnv;

      // 2. Brass fanfare chimes
      double fanfareSample = 0.0;
      if (t < durationSec - 0.5) {
        for (int k = 0; k < fanfareFreqs.length; k++) {
          final freq = fanfareFreqs[k];
          final noteDelay = k * 0.09;
          if (t >= noteDelay) {
            final noteT = t - noteDelay;
            final noteEnv = math.exp(-noteT * 1.5);
            final harmonic2 = brassSheen ? math.sin(2 * math.pi * freq * 2.0 * noteT) * 0.35 : 0.0;
            fanfareSample += (math.sin(2 * math.pi * freq * noteT) * 0.65 + harmonic2) * noteEnv;
          }
        }
        fanfareSample = fanfareSample / fanfareFreqs.length * 0.65;
      }

      final mixed = (crowdSample * crowdIntensity + fanfareSample * 0.55);
      final clamped = mixed.clamp(-1.0, 1.0);
      pcmData[i] = (clamped * 32767).toInt();
    }

    return _buildWavHeader(pcmData, sampleRate);
  }

  /// Synthesizes sharp impact (bat crack or stumps smash) + rising crowd reaction
  Uint8List _synthesizeImpactWithCrowd({
    required double durationSec,
    required double impactFreq,
    double? secondaryFreq,
    required double impactDurationSec,
    required double crowdSurgeDelay,
    required double crowdIntensity,
    required int randomSeed,
  }) {
    const sampleRate = 22050;
    final totalSamples = (sampleRate * durationSec).toInt();
    final pcmData = Int16List(totalSamples);
    final random = math.Random(randomSeed);

    double crowdFilterPrev = 0.0;

    for (int i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;

      // 1. Sharp percussive wood crack impact
      double impactSample = 0.0;
      if (t < impactDurationSec) {
        final decay = math.exp(-t * 90.0);
        final click = (random.nextDouble() * 2.0 - 1.0) * decay * 0.8;
        final sine1 = math.sin(2 * math.pi * impactFreq * t) * decay;
        final sine2 = secondaryFreq != null ? math.sin(2 * math.pi * secondaryFreq * t) * decay * 0.5 : 0.0;
        impactSample = (click + sine1 + sine2).clamp(-1.0, 1.0) * 0.95;
      }

      // 2. Rising crowd roar cheer
      double crowdSample = 0.0;
      if (t >= crowdSurgeDelay) {
        final crowdT = t - crowdSurgeDelay;
        double crowdEnv;
        if (crowdT < 0.3) {
          crowdEnv = crowdT / 0.3; // Rapid rise
        } else if (crowdT < durationSec - crowdSurgeDelay - 0.5) {
          crowdEnv = 1.0;
        } else {
          crowdEnv = math.max(0.0, (durationSec - crowdSurgeDelay - crowdT) / 0.5);
        }

        final whiteNoise = (random.nextDouble() * 2.0 - 1.0);
        crowdFilterPrev = crowdFilterPrev * 0.85 + whiteNoise * 0.15;
        crowdSample = crowdFilterPrev * crowdEnv * crowdIntensity;
      }

      final mixed = (impactSample + crowdSample);
      final clamped = mixed.clamp(-1.0, 1.0);
      pcmData[i] = (clamped * 32767).toInt();
    }

    return _buildWavHeader(pcmData, sampleRate);
  }

  Uint8List _buildWavHeader(Int16List pcmData, int sampleRate) {
    final totalSamples = pcmData.length;
    final byteData = ByteData(44 + totalSamples * 2);

    // RIFF chunk
    byteData.setUint8(0, 0x52); // 'R'
    byteData.setUint8(1, 0x49); // 'I'
    byteData.setUint8(2, 0x46); // 'F'
    byteData.setUint8(3, 0x46); // 'F'
    byteData.setUint32(4, 36 + totalSamples * 2, Endian.little);
    byteData.setUint8(8, 0x57);  // 'W'
    byteData.setUint8(9, 0x41);  // 'A'
    byteData.setUint8(10, 0x56); // 'V'
    byteData.setUint8(11, 0x45); // 'E'

    // 'fmt ' chunk
    byteData.setUint8(12, 0x66); // 'f'
    byteData.setUint8(13, 0x6D); // 'm'
    byteData.setUint8(14, 0x74); // 't'
    byteData.setUint8(15, 0x20); // ' '
    byteData.setUint32(16, 16, Endian.little);
    byteData.setUint16(20, 1, Endian.little);  // PCM
    byteData.setUint16(22, 1, Endian.little);  // Mono
    byteData.setUint32(24, sampleRate, Endian.little);
    byteData.setUint32(28, sampleRate * 2, Endian.little);
    byteData.setUint16(32, 2, Endian.little);  // Block align
    byteData.setUint16(34, 16, Endian.little); // 16-bit

    // 'data' chunk
    byteData.setUint8(36, 0x64); // 'd'
    byteData.setUint8(37, 0x61); // 'a'
    byteData.setUint8(38, 0x74); // 't'
    byteData.setUint8(39, 0x61); // 'a'
    byteData.setUint32(40, totalSamples * 2, Endian.little);

    int offset = 44;
    for (int i = 0; i < totalSamples; i++) {
      byteData.setInt16(offset, pcmData[i], Endian.little);
      offset += 2;
    }

    return byteData.buffer.asUint8List();
  }
}
