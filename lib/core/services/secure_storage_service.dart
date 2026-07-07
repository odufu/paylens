import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureStorageService {
  static const String _appSalt = 'mspay_crypt_salt_2026_!';

  /// Derives a 256-bit key using the master salt and the key name.
  static List<int> _deriveKey(String keyName) {
    final combined = '$_appSalt:$keyName';
    final bytes = utf8.encode(combined);
    return sha256.convert(bytes).bytes;
  }

  /// Encrypts or Decrypts data using a SHA-256 CTR (Counter Mode) stream cipher.
  /// Because it is XOR-based, the same function is used for both encryption and decryption.
  static List<int> _crypt(List<int> input, List<int> key, List<int> iv) {
    final output = List<int>.filled(input.length, 0);
    var blockCount = 0;
    List<int> keystream = [];
    var keystreamIdx = 0;

    for (var i = 0; i < input.length; i++) {
      if (keystreamIdx >= keystream.length) {
        // Generate next 32-byte keystream block: SHA-256(Key + IV + BlockCounter)
        final blockInput = <int>[]
          ..addAll(key)
          ..addAll(iv)
          ..addAll(utf8.encode(blockCount.toString()));
        keystream = sha256.convert(blockInput).bytes;
        keystreamIdx = 0;
        blockCount++;
      }
      output[i] = input[i] ^ keystream[keystreamIdx];
      keystreamIdx++;
    }

    return output;
  }

  /// Saves a string encrypted under a specific key in SharedPreferences.
  static Future<void> writeSecureString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Generate a simple deterministic IV based on the key name
    final iv = sha256.convert(utf8.encode('iv_salt_:$key')).bytes.sublist(0, 16);
    final keyBytes = _deriveKey(key);
    final valueBytes = utf8.encode(value);
    
    final encryptedBytes = _crypt(valueBytes, keyBytes, iv);
    final base64Encrypted = base64.encode(encryptedBytes);
    
    await prefs.setString('enc_:$key', base64Encrypted);
  }

  /// Reads and decrypts a secure string from SharedPreferences.
  static Future<String?> readSecureString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final base64Encrypted = prefs.getString('enc_:$key');
    if (base64Encrypted == null) return null;

    try {
      final iv = sha256.convert(utf8.encode('iv_salt_:$key')).bytes.sublist(0, 16);
      final keyBytes = _deriveKey(key);
      final encryptedBytes = base64.decode(base64Encrypted);
      
      final decryptedBytes = _crypt(encryptedBytes, keyBytes, iv);
      return utf8.decode(decryptedBytes);
    } catch (_) {
      return null;
    }
  }

  /// Deletes a secure key.
  static Future<void> deleteSecureString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('enc_:$key');
  }
}
