import 'package:google_sign_in/google_sign_in.dart';

/// Google sign-in. Written for google_sign_in 7.x.
///
/// Paste the "Web client ID" from the Google Cloud Console here.
/// While it is empty the Google button only shows a hint.
const String kGoogleServerClientId = '';

class GoogleAuth {
  static bool _initialized = false;

  static bool get isConfigured => kGoogleServerClientId.isNotEmpty;

  static Future<void> _ensure() async {
    if (_initialized) {
      return;
    }
    await GoogleSignIn.instance.initialize(serverClientId: kGoogleServerClientId);
    _initialized = true;
  }

  /// Returns the e-mail of the Google account. Throws when it fails or is cancelled.
  static Future<String> signIn() async {
    await _ensure();
    final GoogleSignInAccount account = await GoogleSignIn.instance.authenticate();
    return account.email;
  }

  static Future<void> signOut() async {
    if (!_initialized) {
      return;
    }
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Already signed out.
    }
  }
}
