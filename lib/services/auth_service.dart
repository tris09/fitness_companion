import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import 'secrets.dart';

/// Sign-in logic. Right now accounts stay on this device only.
/// Later a server version (e-mail confirmation, bot check) can replace
/// [LocalAuthService] without changing the screens.

const String kAdminEmail = 'tristanschnitzler@hotmail.de';
const String kTestEmail = 'test@local.test';

/// Marker for the local mode: no account, no password, data only on this device.
const String kLocalUser = 'local';

class AuthUser {
  final String email;
  final bool isAdmin;

  const AuthUser({required this.email, required this.isAdmin});

  bool get isLocal => email == kLocalUser;
}

/// An error with a message that can be shown to the user.
class AuthException implements Exception {
  final String message;

  AuthException(this.message);

  @override
  String toString() => message;
}

abstract class AuthService {
  /// Creates an account and signs it in.
  Future<AuthUser> register(String email, String password);

  Future<AuthUser> signInWithPassword(String email, String password);

  /// Builds the user for an address that was already verified,
  /// for example by Google or from the saved session.
  AuthUser userFor(String email);

  /// Fixed user for the test login. Only the debug build offers it.
  AuthUser get testUser;

  Future<void> signOut();
}

class LocalAuthService implements AuthService {
  static const int _iterations = 10000;

  static String _clean(String email) => email.trim().toLowerCase();

  /// PBKDF2 with HMAC-SHA256, one block (32 bytes).
  static String _hash(String password, List<int> salt) {
    final Hmac hmac = Hmac(sha256, utf8.encode(password));
    List<int> u = hmac.convert(<int>[...salt, 0, 0, 0, 1]).bytes;
    final List<int> result = List<int>.from(u);
    for (int i = 1; i < _iterations; i++) {
      u = hmac.convert(u).bytes;
      for (int k = 0; k < result.length; k++) {
        result[k] ^= u[k];
      }
    }
    return base64Encode(result);
  }

  @override
  AuthUser userFor(String email) {
    final String clean = _clean(email);
    return AuthUser(email: clean, isAdmin: clean == kAdminEmail);
  }

  @override
  AuthUser get testUser => const AuthUser(email: kTestEmail, isAdmin: true);

  @override
  Future<AuthUser> register(String email, String password) async {
    final String clean = _clean(email);
    if (!isValidEmail(clean)) {
      throw AuthException('Bitte gib eine gültige E-Mail-Adresse ein.');
    }
    final String? problem = passwordProblem(password);
    if (problem != null) {
      throw AuthException(problem);
    }
    final Map<String, dynamic> accounts = await Secrets.readAccounts();
    if (accounts.containsKey(clean) || clean == kTestEmail) {
      throw AuthException('Mit dieser E-Mail gibt es schon ein Konto auf diesem Gerät.');
    }
    final Random rnd = Random.secure();
    final List<int> salt = List<int>.generate(16, (int _) => rnd.nextInt(256));
    accounts[clean] = <String, dynamic>{'salt': base64Encode(salt), 'hash': _hash(password, salt)};
    final bool ok = await Secrets.writeAccounts(accounts);
    if (!ok) {
      throw AuthException('Das Konto konnte nicht gespeichert werden.');
    }
    return userFor(clean);
  }

  @override
  Future<AuthUser> signInWithPassword(String email, String password) async {
    final String clean = _clean(email);
    final Map<String, dynamic> accounts = await Secrets.readAccounts();
    final dynamic entry = accounts[clean];
    const String wrong = 'E-Mail oder Passwort stimmt nicht.';
    if (entry is! Map) {
      throw AuthException(wrong);
    }
    final List<int> salt = base64Decode('${entry['salt']}');
    if (_hash(password, salt) != '${entry['hash']}') {
      throw AuthException(wrong);
    }
    return userFor(clean);
  }

  @override
  Future<void> signOut() async {}
}

bool isValidEmail(String input) {
  return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(input.trim());
}

/// Returns a message when the password is too weak, otherwise null.
String? passwordProblem(String password) {
  if (password.length < 8) {
    return 'Das Passwort braucht mindestens 8 Zeichen.';
  }
  if (!RegExp(r'[0-9]').hasMatch(password) || !RegExp(r'[A-Za-z]').hasMatch(password)) {
    return 'Das Passwort braucht Buchstaben und Zahlen.';
  }
  return null;
}
