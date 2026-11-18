import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Sign in with an e-mail address only. No password.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _email = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final String value = _email.text.trim();
    if (!isValidEmail(value)) {
      setState(() {
        _error = 'Bitte gib eine gültige E-Mail-Adresse ein.';
      });
      return;
    }
    setState(() {
      _error = null;
      _busy = true;
    });
    try {
      await AppScope.of(context).signIn(value);
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Die Anmeldung hat nicht geklappt.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
          children: <Widget>[
            const SectionLabel('Willkommen'),
            const SizedBox(height: 8),
            Text('ANMELDEN', style: heading(context, 56)),
            const SizedBox(height: 14),
            Text(
              'Melde dich mit deiner E-Mail-Adresse an. Ein Passwort brauchst du nicht.',
              style: bodyStyle(context, size: 16, color: c.text2),
            ),
            const SizedBox(height: 28),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              textInputAction: TextInputAction.done,
              onSubmitted: (String _) => _submit(),
              style: bodyStyle(context, size: 17, weight: FontWeight.w500),
              cursorColor: c.accentText,
              decoration: fieldDecoration(context, 'E-Mail', hint: 'name@beispiel.de', errorText: _error),
            ),
            const SizedBox(height: 16),
            PrimaryButton(label: 'Anmelden', height: 64, fontSize: 22, onPressed: _busy ? null : _submit),
            const SizedBox(height: 12),
            SecondaryButton(
              label: 'Mit Google anmelden',
              height: 56,
              onPressed: _busy
                  ? null
                  : () async {
                      final String? message = await AppScope.of(context).signInWithGoogle();
                      if (message != null && mounted) {
                        setState(() {
                          _error = message;
                        });
                      }
                    },
            ),
            const SizedBox(height: 16),
            Text(
              'Im Moment wird die Adresse nur auf diesem Gerät gespeichert. Die Bestätigung per E-Mail kommt mit dem Server.',
              style: bodyStyle(context, size: 13, color: c.text2),
            ),
          ],
        ),
      ),
    );
  }
}
