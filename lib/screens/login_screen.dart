import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Sign in or register with e-mail and password, or continue with Google.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _repeat = TextEditingController();

  bool _register = false;
  bool _showPassword = false;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _repeat.dispose();
    super.dispose();
  }

  void _setMode(bool register) {
    setState(() {
      _register = register;
      _error = null;
    });
  }

  Future<void> _submit() async {
    final AppState state = AppScope.of(context);
    final String email = _email.text.trim();
    final String password = _password.text;
    if (!isValidEmail(email)) {
      setState(() => _error = 'Bitte gib eine gültige E-Mail-Adresse ein.');
      return;
    }
    if (_register) {
      final String? problem = passwordProblem(password);
      if (problem != null) {
        setState(() => _error = problem);
        return;
      }
      if (password != _repeat.text) {
        setState(() => _error = 'Die beiden Passwörter sind nicht gleich.');
        return;
      }
    } else if (password.isEmpty) {
      setState(() => _error = 'Bitte gib dein Passwort ein.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _error = null;
      _busy = true;
    });
    final String? message = _register
        ? await state.register(email, password)
        : await state.signInWithPassword(email, password);
    if (!mounted) {
      return;
    }
    // On success the AuthGate swaps this screen, so only errors are handled here.
    if (message != null) {
      setState(() {
        _busy = false;
        _error = message;
      });
    }
  }

  Future<void> _google() async {
    setState(() => _busy = true);
    final String? message = await AppScope.of(context).signInWithGoogle();
    if (message != null && mounted) {
      setState(() {
        _busy = false;
        _error = message;
      });
    }
  }

  InputDecoration _passwordDecoration(String label) {
    final AppColors c = AppColors.of(context);
    return fieldDecoration(context, label).copyWith(
      suffixIcon: IconButton(
        icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility, color: c.text2),
        onPressed: () => setState(() => _showPassword = !_showPassword),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 40, 20, 24),
          children: <Widget>[
            const SectionLabel('Willkommen'),
            const SizedBox(height: 8),
            Text(_register ? 'REGISTRIEREN' : 'ANMELDEN', style: heading(context, 52)),
            const SizedBox(height: 20),
            EvenGrid(
              columns: 2,
              children: <Widget>[
                InkWell(onTap: () => _setMode(false), child: ChipBox(text: 'Anmelden', selected: !_register, height: 48)),
                InkWell(onTap: () => _setMode(true), child: ChipBox(text: 'Registrieren', selected: _register, height: 48)),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              textInputAction: TextInputAction.next,
              style: bodyStyle(context, size: 17, weight: FontWeight.w500),
              cursorColor: c.accentText,
              decoration: fieldDecoration(context, 'E-Mail', hint: 'name@beispiel.de'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              obscureText: !_showPassword,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: _register ? TextInputAction.next : TextInputAction.done,
              onSubmitted: (String _) {
                if (!_register) {
                  _submit();
                }
              },
              style: bodyStyle(context, size: 17, weight: FontWeight.w500),
              cursorColor: c.accentText,
              decoration: _passwordDecoration('Passwort'),
            ),
            Reveal(
              show: _register,
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: TextField(
                  controller: _repeat,
                  obscureText: !_showPassword,
                  autocorrect: false,
                  enableSuggestions: false,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (String _) => _submit(),
                  style: bodyStyle(context, size: 17, weight: FontWeight.w500),
                  cursorColor: c.accentText,
                  decoration: _passwordDecoration('Passwort wiederholen'),
                ),
              ),
            ),
            Reveal(
              show: _register,
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Mindestens 8 Zeichen, mit Buchstaben und Zahlen.',
                  style: bodyStyle(context, size: 13, color: c.text2),
                ),
              ),
            ),
            Reveal(
              show: _error != null,
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_error ?? '', style: bodyStyle(context, size: 14, weight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: _busy ? 'Einen Moment …' : (_register ? 'Konto erstellen' : 'Anmelden'),
              height: 64,
              fontSize: 22,
              onPressed: _busy ? null : _submit,
            ),
            const SizedBox(height: 12),
            SecondaryButton(label: 'Mit Google anmelden', height: 56, onPressed: _busy ? null : _google),
            const SizedBox(height: 12),
            SecondaryButton(
              label: 'Ohne Konto starten',
              height: 56,
              onPressed: _busy ? null : () => AppScope.of(context).startLocal(),
            ),
            const SizedBox(height: 6),
            Text(
              'Ohne Konto bleibt alles auf diesem Handy. Kein Passwort nötig. Ein Konto kannst du später anlegen.',
              style: bodyStyle(context, size: 13, color: c.text2),
            ),
            if (kDebugMode) ...<Widget>[
              const SizedBox(height: 12),
              SecondaryButton(
                label: 'Test-Login (ohne Profil)',
                height: 48,
                fontSize: 17,
                onPressed: _busy ? null : () => AppScope.of(context).signInAsTest(),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'Dein Konto liegt im Moment nur auf diesem Gerät. Das Passwort wird nie im Klartext gespeichert. Mit dem Server kommen E-Mail-Bestätigung und Passwort-Zurücksetzen.',
              style: bodyStyle(context, size: 13, color: c.text2),
            ),
          ],
        ),
      ),
    );
  }
}
