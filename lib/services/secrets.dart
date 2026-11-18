import 'dart:convert';

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

  /// Removes everything this app stored in the protected storage.
  static Future<void> deleteAll() async {
    try {
      await _storage.deleteAll();
    } catch (_) {
      // Nothing to do.
    }
  }

  static const String _accounts = 'local_accounts';

  /// Local accounts: e-mail -> salt and password hash. Never the password itself.
  static Future<Map<String, dynamic>> readAccounts() async {
    try {
      final String? raw = await _storage.read(key: _accounts);
      if (raw == null || raw.isEmpty) {
        return <String, dynamic>{};
      }
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  static Future<bool> writeAccounts(Map<String, dynamic> accounts) async {
    try {
      await _storage.write(key: _accounts, value: jsonEncode(accounts));
      return true;
    } catch (_) {
      return false;
    }
  }
}
