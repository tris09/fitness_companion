import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Keeps the user's Gemini API key in the protected storage of the phone.
class Secrets {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _geminiKey = 'gemini_api_key';

  static Future<String?> readGeminiKey() async {
    try {
      final String? v = await _storage.read(key: _geminiKey);
      return (v == null || v.isEmpty) ? null : v;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> writeGeminiKey(String value) async {
    try {
      await _storage.write(key: _geminiKey, value: value.trim());
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> deleteGeminiKey() async {
    try {
      await _storage.delete(key: _geminiKey);
    } catch (_) {
      // Nothing to do.
    }
  }
}
