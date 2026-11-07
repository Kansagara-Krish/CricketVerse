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

  bool get isSoundEnabled => _isSoundEnabled;

  Uint8List? _cached50SoundBytes;
  Uint8List? _cached100SoundBytes;

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

  Future<void> playCelebrationSound(String type) async {
    if (!_isSoundEnabled) return;
    try {
      _player ??= AudioPlayer();

      await _player?.stop();

      final bytes = type == '100' ? _getOrGenerate100Sound() : _getOrGenerate50Sound();
      await _player?.play(BytesSource(bytes));
    } catch (e) {
      debugPrint('Error playing celebration sound ($type): $e');
    }
  }

  Future<void> stop() async {
    try {
      await _player?.stop();
    } catch (_) {}
  }

  void dispose() {
    _player?.dispose();
    _player = null;
  }

  Uint8List _getOrGenerate50Sound() {
    if (_cached50SoundBytes != null) return _cached50SoundBytes!;
    // Generate 2.5 seconds of subtle crowd clapping/cheering with gentle fanfare
    _cached50SoundBytes = _synthesizeCelebrationWav(
      durationSec: 2.5,
      isCentury: false,
    );
    return _cached50SoundBytes!;
  }

  Uint8List _getOrGenerate100Sound() {
    if (_cached100SoundBytes != null) return _cached100SoundBytes!;
    // Generate 4.5 seconds of thundering stadium roar + triumphant brass chords
    _cached100SoundBytes = _synthesizeCelebrationWav(
      durationSec: 4.5,
      isCentury: true,
    );
    return _cached100SoundBytes!;
  }

  /// Synthesizes a clean 16-bit mono 22050 Hz PCM WAV audio in memory
  Uint8List _synthesizeCelebrationWav({
    required double durationSec,
    required bool isCentury,
  }) {
    const sampleRate = 22050;
    final totalSamples = (sampleRate * durationSec).toInt();
    final pcmData = Int16List(totalSamples);
    final random = math.Random(isCentury ? 100 : 50);

    // Chords (frequencies in Hz):
    // Half-century: pleasant rising notes (C5, E5, G5)
    // Century: grand stadium fanfare (C4, G4, C5, E5, G5, C6)
    final fanfareFreqs = isCentury
        ? [261.63, 392.00, 523.25, 659.25, 783.99, 1046.50]
        : [523.25, 659.25, 783.99];

    // Bandpass crowd noise state
    double crowdFilterPrev = 0.0;

    for (int i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;

      // 1. Crowd applause & roar envelope
      double crowdEnv;
      if (t < 0.3) {
        crowdEnv = t / 0.3; // Attack
      } else if (t < durationSec - 0.8) {
        crowdEnv = 1.0; // Sustain
      } else {
        crowdEnv = math.max(0.0, (durationSec - t) / 0.8); // Decay
      }

      // White noise with soft low-pass filter for crowd texture
      final whiteNoise = (random.nextDouble() * 2.0 - 1.0);
      crowdFilterPrev = crowdFilterPrev * 0.82 + whiteNoise * 0.18;

      // Clapping impulses (stochastic bursts)
      double clap = 0.0;
      if (random.nextDouble() < (isCentury ? 0.09 : 0.05)) {
        clap = (random.nextDouble() * 2.0 - 1.0) * (isCentury ? 0.5 : 0.3);
      }

      double crowdSample = (crowdFilterPrev * 0.7 + clap) * crowdEnv;

      // 2. Triumphant Fanfare brass chime
      double fanfareSample = 0.0;
      if (t < (isCentury ? 3.0 : 1.8)) {
        for (int k = 0; k < fanfareFreqs.length; k++) {
          final freq = fanfareFreqs[k];
          // Staggered arpeggiated entrance
          final noteDelay = k * (isCentury ? 0.08 : 0.12);
          if (t >= noteDelay) {
            final noteT = t - noteDelay;
            final noteEnv = math.exp(-noteT * (isCentury ? 1.4 : 2.2));
            // Add fundamental + soft 2nd harmonic for brassy sheen
            fanfareSample += (math.sin(2 * math.pi * freq * noteT) * 0.7 +
                    math.sin(2 * math.pi * freq * 2.0 * noteT) * 0.3) *
                noteEnv;
          }
        }
        fanfareSample = fanfareSample / fanfareFreqs.length * (isCentury ? 0.75 : 0.55);
      }

      // 3. Combined & normalized to 16-bit range
      final mixed = (crowdSample * (isCentury ? 0.45 : 0.35) + fanfareSample * 0.55);
      final clamped = mixed.clamp(-1.0, 1.0);
      pcmData[i] = (clamped * 32767).toInt();
    }

    // Build standard 44-byte WAV Header
    final byteData = ByteData(44 + totalSamples * 2);

    // RIFF chunk descriptor
    byteData.setUint8(0, 0x52); // 'R'
    byteData.setUint8(1, 0x49); // 'I'
    byteData.setUint8(2, 0x46); // 'F'
    byteData.setUint8(3, 0x46); // 'F'
    byteData.setUint32(4, 36 + totalSamples * 2, Endian.little);
    byteData.setUint8(8, 0x57);  // 'W'
    byteData.setUint8(9, 0x41);  // 'A'
    byteData.setUint8(10, 0x56); // 'V'
    byteData.setUint8(11, 0x45); // 'E'

    // 'fmt ' sub-chunk
    byteData.setUint8(12, 0x66); // 'f'
    byteData.setUint8(13, 0x6D); // 'm'
    byteData.setUint8(14, 0x74); // 't'
    byteData.setUint8(15, 0x20); // ' '
    byteData.setUint32(16, 16, Endian.little); // Subchunk1Size (16 for PCM)
    byteData.setUint16(20, 1, Endian.little);  // AudioFormat (1 for PCM)
    byteData.setUint16(22, 1, Endian.little);  // NumChannels (1 = Mono)
    byteData.setUint32(24, sampleRate, Endian.little); // SampleRate
    byteData.setUint32(28, sampleRate * 2, Endian.little); // ByteRate (SampleRate * 1 * 2)
    byteData.setUint16(32, 2, Endian.little);  // BlockAlign (1 * 2)
    byteData.setUint16(34, 16, Endian.little); // BitsPerSample (16)

    // 'data' sub-chunk
    byteData.setUint8(36, 0x64); // 'd'
    byteData.setUint8(37, 0x61); // 'a'
    byteData.setUint8(38, 0x74); // 't'
    byteData.setUint8(39, 0x61); // 'a'
    byteData.setUint32(40, totalSamples * 2, Endian.little); // Subchunk2Size

    // Write PCM samples
    int offset = 44;
    for (int i = 0; i < totalSamples; i++) {
      byteData.setInt16(offset, pcmData[i], Endian.little);
      offset += 2;
    }

    return byteData.buffer.asUint8List();
  }
}
