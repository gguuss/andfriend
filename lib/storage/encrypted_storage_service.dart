import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:shared_preferences/shared_preferences.dart';

/// Local Encrypted Storage Service providing zero-cloud AES-256 persistence.
/// All companion data, habit records, streaks, and reflections are encrypted
/// locally on-device with zero telemetry and zero network leakage.
class EncryptedStorageService {
  static final EncryptedStorageService instance = EncryptedStorageService._internal();

  EncryptedStorageService._internal();

  enc.Key? _key;
  bool _initialized = false;

  static const String _seedPrefKey = 'andfriend_sec_seed_v1';
  static const String _magicPrefix = 'enc:v1:';

  /// Initializes the local master key derivation from device-unique entropy.
  Future<void> init() async {
    if (_initialized && _key != null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      String? seed = prefs.getString(_seedPrefKey);
      if (seed == null) {
        final rng = math.Random.secure();
        final bytes = List<int>.generate(32, (_) => rng.nextInt(256));
        seed = base64UrlEncode(bytes);
        await prefs.setString(_seedPrefKey, seed);
      }

      // Derive a 256-bit AES master key via SHA-256 hashing
      final hash = sha256.convert(utf8.encode('andfriend_local_vault_salt_$seed')).bytes;
      _key = enc.Key(Uint8List.fromList(hash));
      _initialized = true;
    } catch (_) {
      // Fallback in test/headless environments
      final hash = sha256.convert(utf8.encode('andfriend_local_vault_fallback_seed')).bytes;
      _key = enc.Key(Uint8List.fromList(hash));
      _initialized = true;
    }
  }

  /// Encrypts plaintext string using AES-256-CBC with a cryptographically secure dynamic IV.
  /// Formats output payload as: `enc:v1:<base64-iv>:<base64-ciphertext>`
  String encrypt(String plainText) {
    _ensureKey();

    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(_key!, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encrypt(plainText, iv: iv);

    return '$_magicPrefix${iv.base64}:${encrypted.base64}';
  }

  /// Decrypts an encrypted payload. If payload is unencrypted legacy text,
  /// returns it gracefully without data corruption.
  String decrypt(String payload) {
    if (!payload.startsWith(_magicPrefix)) {
      // Gracefully return legacy unencrypted plaintext
      return payload;
    }

    _ensureKey();

    final raw = payload.substring(_magicPrefix.length);
    final separatorIdx = raw.indexOf(':');
    if (separatorIdx == -1) return '';

    final ivStr = raw.substring(0, separatorIdx);
    final cipherStr = raw.substring(separatorIdx + 1);

    try {
      final iv = enc.IV.fromBase64(ivStr);
      final encrypter = enc.Encrypter(enc.AES(_key!, mode: enc.AESMode.cbc));
      return encrypter.decrypt64(cipherStr, iv: iv);
    } catch (_) {
      // In case of tampering or key mismatch, return empty string safely
      return '';
    }
  }

  void _ensureKey() {
    if (_key == null) {
      final hash = sha256.convert(utf8.encode('andfriend_local_vault_fallback_seed')).bytes;
      _key = enc.Key(Uint8List.fromList(hash));
      _initialized = true;
    }
  }

  /// Writes encrypted string value to persistent local storage.
  Future<void> writeSecure(String key, String value) async {
    await init();
    final cipherPayload = encrypt(value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, cipherPayload);
  }

  /// Reads and decrypts stored value from local storage.
  Future<String?> readSecure(String key) async {
    await init();
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return null;
    return decrypt(raw);
  }

  /// Encrypts and writes a JSON map to persistent local storage.
  Future<void> writeSecureJson(String key, Map<String, dynamic> data) async {
    final jsonStr = jsonEncode(data);
    await writeSecure(key, jsonStr);
  }

  /// Reads and decrypts a JSON map from local storage.
  Future<Map<String, dynamic>?> readSecureJson(String key) async {
    final decrypted = await readSecure(key);
    if (decrypted == null) return null;
    try {
      return jsonDecode(decrypted) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
