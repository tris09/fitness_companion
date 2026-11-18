/// Sign-in logic. Right now everything stays on the device.
/// Later a server version (e-mail confirmation, bot check) can replace
/// [LocalAuthService] without changing the screens.

const String kAdminEmail = 'tristanschnitzler@hotmail.de';

class AuthUser {
  final String email;
  final bool isAdmin;

  const AuthUser({required this.email, required this.isAdmin});
}

abstract class AuthService {
  Future<AuthUser> signInWithEmail(String email);
  Future<void> signOut();
}

class LocalAuthService implements AuthService {
  @override
  Future<AuthUser> signInWithEmail(String email) async {
    final String clean = email.trim().toLowerCase();
    return AuthUser(email: clean, isAdmin: clean == kAdminEmail);
  }

  @override
  Future<void> signOut() async {}
}

bool isValidEmail(String input) {
  return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(input.trim());
}
