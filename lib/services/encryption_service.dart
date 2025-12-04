import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EncryptionService {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Generate a random encryption key
  static String _generateKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Encode(bytes);
  }

  // Get or create encryption key
  static Future<String> getEncryptionKey() async {
    const keyName = 'encryption_key';
    String? key = await _secureStorage.read(key: keyName);

    if (key == null) {
      key = _generateKey();
      await _secureStorage.write(key: keyName, value: key);
    }

    return key;
  }

  // Simple XOR encryption (for demonstration - in production use AES)
  static String _xorEncrypt(String text, String key) {
    final textBytes = utf8.encode(text);
    final keyBytes = base64Decode(key);
    final encrypted = <int>[];

    for (int i = 0; i < textBytes.length; i++) {
      encrypted.add(textBytes[i] ^ keyBytes[i % keyBytes.length]);
    }

    return base64Encode(encrypted);
  }

  // Simple XOR decryption
  static String _xorDecrypt(String encryptedText, String key) {
    final encryptedBytes = base64Decode(encryptedText);
    final keyBytes = base64Decode(key);
    final decrypted = <int>[];

    for (int i = 0; i < encryptedBytes.length; i++) {
      decrypted.add(encryptedBytes[i] ^ keyBytes[i % keyBytes.length]);
    }

    return utf8.decode(decrypted);
  }

  // Encrypt sensitive data
  static Future<String> encrypt(String data) async {
    if (data.isEmpty) return data;

    final key = await getEncryptionKey();
    return _xorEncrypt(data, key);
  }

  // Decrypt sensitive data
  static Future<String> decrypt(String encryptedData) async {
    if (encryptedData.isEmpty) return encryptedData;

    try {
      final key = await getEncryptionKey();
      return _xorDecrypt(encryptedData, key);
    } catch (e) {
      // If decryption fails, return the original data
      return encryptedData;
    }
  }

  // Hash password with salt
  static String hashPassword(String password, {String? salt}) {
    salt ??= _generateSalt();
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return '$salt:${digest.toString()}';
  }

  // Verify password
  static bool verifyPassword(String password, String hashedPassword) {
    try {
      final parts = hashedPassword.split(':');
      if (parts.length != 2) return false;

      final salt = parts[0];

      final testHash = hashPassword(password, salt: salt);
      return testHash == hashedPassword;
    } catch (e) {
      return false;
    }
  }

  // Generate random salt
  static String _generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (i) => random.nextInt(256));
    return base64Encode(bytes);
  }

  // Store encrypted data in secure storage
  static Future<void> storeSecure(String key, String value) async {
    final encryptedValue = await encrypt(value);
    await _secureStorage.write(key: key, value: encryptedValue);
  }

  // Retrieve and decrypt data from secure storage
  static Future<String?> getSecure(String key) async {
    final encryptedValue = await _secureStorage.read(key: key);
    if (encryptedValue == null) return null;

    return await decrypt(encryptedValue);
  }

  // Delete secure data
  static Future<void> deleteSecure(String key) async {
    await _secureStorage.delete(key: key);
  }

  // Clear all secure data
  static Future<void> clearAllSecure() async {
    await _secureStorage.deleteAll();
  }

  // Check if biometric authentication is available
  static Future<bool> isBiometricAvailable() async {
    // This would be implemented with local_auth package
    // For now, return false
    return false;
  }

  // Generate secure random string
  static String generateSecureRandomString(int length) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random.secure();
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }
}
