import 'package:flutter/material.dart';

import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/root_screen.dart';
import 'services/notifications.dart';
import 'state.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final AppState state = AppState();
  await state.load();
  runApp(AppScope(notifier: state, child: const FitnessApp()));
  // Plan the reminders for the next days every time the app starts.
  NotificationService.instance.reschedule(state.stretch);
}

class FitnessApp extends StatelessWidget {
  const FitnessApp({super.key});

  @override
  Widget build(BuildContext context) {
    final AppState state = AppScope.of(context);
    return MaterialApp(
      title: 'Fitness Companion',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: state.themeMode,
      home: const AuthGate(),
    );
  }
}

/// Shows the login until a user is signed in.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final AppState state = AppScope.of(context);
    if (state.user == null) {
      return const LoginScreen();
    }
    if (!state.body.done) {
      return const OnboardingScreen();
    }
    return const RootScreen();
  }
}
