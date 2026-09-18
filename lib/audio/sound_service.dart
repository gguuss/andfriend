import 'dart:math' as math;
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SoundService {
  static final SoundService instance = SoundService._internal();

  SoundService._internal() {
    _init();
  }

  final AudioPlayer _player = AudioPlayer();
  bool _isMuted = false;
  double _volume = 0.8;

  bool get isMuted => _isMuted;
  double get volume => _volume;

  // Cached generated sound byte caches
  final Map<String, Uint8List> _wavCache = {};

  Future<void> _init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isMuted = prefs.getBool('sound_muted') ?? false;
      _volume = prefs.getDouble('sound_volume') ?? 0.8;
      await _player.setVolume(_volume);

      // Pre-warm procedural audio sounds
      _generateAllSounds();
    } catch (e) {
      debugPrint('SoundService init error: $e');
    }
  }

  Future<void> toggleMute() async {
    _isMuted = !_isMuted;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('sound_muted', _isMuted);
    } catch (_) {}
  }

  Future<void> setVolume(double vol) async {
    _volume = vol.clamp(0.0, 1.0);
    await _player.setVolume(_volume);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('sound_volume', _volume);
    } catch (_) {}
  }

  void playChirp({double pitchMultiplier = 1.0}) {
    _playSound('chirp', () => _synthesizeChirp(pitchMultiplier));
  }

  void playGiggle() {
    _playSound('giggle', () => _synthesizeGiggle());
  }

  void playMunch() {
    _playSound('munch', () => _synthesizeMunch());
  }

  void playSnore() {
    _playSound('snore', () => _synthesizeSnore());
  }

  void playDig() {
    _playSound('dig', () => _synthesizeDig());
  }

  void playFanfare() {
    _playSound('fanfare', () => _synthesizeFanfare());
  }

  void playHighFive() {
    _playSound('highFive', () => _synthesizeHighFive());
  }

  void playWhoosh() {
    _playSound('whoosh', () => _synthesizeWhoosh());
  }

  void _playSound(String name, Uint8List Function() generator) async {
    if (_isMuted) return;

    try {
      Uint8List? bytes = _wavCache[name];
      if (bytes == null) {
        bytes = generator();
        _wavCache[name] = bytes;
      }

      // AudioPlayer play from bytes source
      await _player.stop();
      await _player.play(BytesSource(bytes));
    } catch (e) {
      debugPrint('SoundService play error: $e');
    }
  }

  void _generateAllSounds() {
    _wavCache['chirp'] = _synthesizeChirp(1.0);
    _wavCache['giggle'] = _synthesizeGiggle();
    _wavCache['munch'] = _synthesizeMunch();
    _wavCache['snore'] = _synthesizeSnore();
    _wavCache['dig'] = _synthesizeDig();
    _wavCache['fanfare'] = _synthesizeFanfare();
    _wavCache['highFive'] = _synthesizeHighFive();
    _wavCache['whoosh'] = _synthesizeWhoosh();
  }

  // --- Procedural PCM WAV Synthesizers (22050Hz, 16-bit mono) ---

  static Uint8List _synthesizeChirp(double pitchMult) {
    const sampleRate = 22050;
    const durationSec = 0.22;
    final numSamples = (sampleRate * durationSec).toInt();
    final pcm = Int16List(numSamples);

    final startFreq = 480.0 * pitchMult;
    final endFreq = 1250.0 * pitchMult;

    for (int i = 0; i < numSamples; i++) {
      final t = i / numSamples;
      // Exponential sweep
      final freq = startFreq * math.pow(endFreq / startFreq, t);
      final phase = 2 * math.pi * freq * (i / sampleRate);

      // Amplitude envelope: quick attack, smooth decay
      final env = math.sin(t * math.pi);
      final sample = (math.sin(phase) * env * 24000).toInt();
      pcm[i] = sample.clamp(-32767, 32767);
    }

    return _createWav(pcm, sampleRate);
  }

  static Uint8List _synthesizeGiggle() {
    const sampleRate = 22050;
    const durationSec = 0.35;
    final numSamples = (sampleRate * durationSec).toInt();
    final pcm = Int16List(numSamples);

    for (int i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      // High-pitched bubbling modulation
      final vibrato = math.sin(2 * math.pi * 18.0 * t);
      final freq = 750.0 + (vibrato * 250.0);
      final phase = 2 * math.pi * freq * t;

      final env = (1.0 - (i / numSamples)) * math.sin((i / numSamples) * math.pi);
      final sample = (math.sin(phase) * env * 26000).toInt();
      pcm[i] = sample.clamp(-32767, 32767);
    }

    return _createWav(pcm, sampleRate);
  }

  static Uint8List _synthesizeMunch() {
    const sampleRate = 22050;
    const durationSec = 0.25;
    final numSamples = (sampleRate * durationSec).toInt();
    final pcm = Int16List(numSamples);
    final rng = math.Random(42);

    for (int i = 0; i < numSamples; i++) {
      final t = i / numSamples;
      // Noise burst mixed with low thud
      final noise = (rng.nextDouble() * 2.0 - 1.0);
      final thud = math.sin(2 * math.pi * 120.0 * (i / sampleRate));

      // Multi-crunch pulse envelope
      final pulse = math.pow(math.sin(t * 3 * math.pi).abs(), 2);
      final env = (1.0 - t) * pulse;

      final sample = ((noise * 0.7 + thud * 0.3) * env * 28000).toInt();
      pcm[i] = sample.clamp(-32767, 32767);
    }

    return _createWav(pcm, sampleRate);
  }

  static Uint8List _synthesizeSnore() {
    const sampleRate = 22050;
    const durationSec = 0.6;
    final numSamples = (sampleRate * durationSec).toInt();
    final pcm = Int16List(numSamples);

    for (int i = 0; i < numSamples; i++) {
      final t = i / numSamples;
      // Low gentle swell
      final freq = 110.0 + (math.sin(t * math.pi) * 30.0);
      final phase = 2 * math.pi * freq * (i / sampleRate);

      final env = math.sin(t * math.pi);
      // Soft triangle/sine wave
      final sample = (math.sin(phase) * env * 18000).toInt();
      pcm[i] = sample.clamp(-32767, 32767);
    }

    return _createWav(pcm, sampleRate);
  }

  static Uint8List _synthesizeDig() {
    const sampleRate = 22050;
    const durationSec = 0.28;
    final numSamples = (sampleRate * durationSec).toInt();
    final pcm = Int16List(numSamples);
    final rng = math.Random(1337);

    for (int i = 0; i < numSamples; i++) {
      final t = i / numSamples;
      // Scratchy rustle
      final noise = (rng.nextDouble() * 2.0 - 1.0);
      final scratch = math.sin(2 * math.pi * 800.0 * (i / sampleRate));

      final pulse = math.sin(t * 4 * math.pi).abs();
      final env = (1.0 - t) * pulse;

      final sample = ((noise * 0.8 + scratch * 0.2) * env * 24000).toInt();
      pcm[i] = sample.clamp(-32767, 32767);
    }

    return _createWav(pcm, sampleRate);
  }

  static Uint8List _synthesizeFanfare() {
    const sampleRate = 22050;
    const durationSec = 0.55;
    final numSamples = (sampleRate * durationSec).toInt();
    final pcm = Int16List(numSamples);

    // Arpeggio: C5 (523Hz), E5 (659Hz), G5 (784Hz), C6 (1046Hz)
    final notes = [523.25, 659.25, 783.99, 1046.50];
    final noteLength = numSamples ~/ notes.length;

    for (int i = 0; i < numSamples; i++) {
      final noteIndex = (i ~/ noteLength).clamp(0, notes.length - 1);
      final freq = notes[noteIndex];
      final localSample = i % noteLength;
      final localT = localSample / noteLength;

      final phase = 2 * math.pi * freq * (i / sampleRate);
      final env = (1.0 - localT) * math.sin(localT * math.pi);

      final sample = (math.sin(phase) * env * 28000).toInt();
      pcm[i] = sample.clamp(-32767, 32767);
    }

    return _createWav(pcm, sampleRate);
  }

  static Uint8List _synthesizeHighFive() {
    const sampleRate = 22050;
    const durationSec = 0.18;
    final numSamples = (sampleRate * durationSec).toInt();
    final pcm = Int16List(numSamples);

    for (int i = 0; i < numSamples; i++) {
      final t = i / numSamples;
      final freq = 880.0 + (1.0 - t) * 400.0;
      final phase = 2 * math.pi * freq * (i / sampleRate);
      final env = math.pow(1.0 - t, 2);

      final sample = (math.sin(phase) * env * 30000).toInt();
      pcm[i] = sample.clamp(-32767, 32767);
    }

    return _createWav(pcm, sampleRate);
  }

  static Uint8List _synthesizeWhoosh() {
    const sampleRate = 22050;
    const durationSec = 0.38;
    final numSamples = (sampleRate * durationSec).toInt();
    final pcm = Int16List(numSamples);
    final rng = math.Random(777);

    for (int i = 0; i < numSamples; i++) {
      final t = i / numSamples;
      // White noise with swept bandpass/filter simulation
      final noise = (rng.nextDouble() * 2.0 - 1.0);
      final centerFreq = 300.0 + math.sin(t * math.pi) * 800.0;
      final tone = math.sin(2 * math.pi * centerFreq * (i / sampleRate));

      // Parabolic smooth envelope
      final env = math.sin(t * math.pi);
      final sample = ((noise * 0.75 + tone * 0.25) * env * 22000).toInt();
      pcm[i] = sample.clamp(-32767, 32767);
    }

    return _createWav(pcm, sampleRate);
  }

  // --- Helper to assemble standard RIFF WAV header ---
  static Uint8List _createWav(Int16List pcm, int sampleRate) {
    final byteCount = pcm.length * 2;
    final buffer = ByteData(44 + byteCount);

    // RIFF chunk
    buffer.setUint8(0, 0x52); // 'R'
    buffer.setUint8(1, 0x49); // 'I'
    buffer.setUint8(2, 0x46); // 'F'
    buffer.setUint8(3, 0x46); // 'F'
    buffer.setUint32(4, 36 + byteCount, Endian.little);
    buffer.setUint8(8, 0x57);  // 'W'
    buffer.setUint8(9, 0x41);  // 'A'
    buffer.setUint8(10, 0x56); // 'V'
    buffer.setUint8(11, 0x45); // 'E'

    // fmt chunk
    buffer.setUint8(12, 0x66); // 'f'
    buffer.setUint8(13, 0x6D); // 'm'
    buffer.setUint8(14, 0x74); // 't'
    buffer.setUint8(15, 0x20); // ' '
    buffer.setUint32(16, 16, Endian.little); // Chunk size
    buffer.setUint16(20, 1, Endian.little);  // PCM format
    buffer.setUint16(22, 1, Endian.little);  // Mono (1 channel)
    buffer.setUint32(24, sampleRate, Endian.little);
    buffer.setUint32(28, sampleRate * 2, Endian.little); // Byte rate
    buffer.setUint16(32, 2, Endian.little);  // Block align
    buffer.setUint16(34, 16, Endian.little); // Bits per sample

    // data chunk
    buffer.setUint8(36, 0x64); // 'd'
    buffer.setUint8(37, 0x61); // 'a'
    buffer.setUint8(38, 0x74); // 't'
    buffer.setUint8(39, 0x61); // 'a'
    buffer.setUint32(40, byteCount, Endian.little);

    // Fill PCM samples
    int offset = 44;
    for (int i = 0; i < pcm.length; i++) {
      buffer.setInt16(offset, pcm[i], Endian.little);
      offset += 2;
    }

    return buffer.buffer.asUint8List();
  }
}
