import 'package:flutter/material.dart';

import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/root_screen.dart';
import 'screens/stretch_screen.dart';
import 'services/notifications.dart';
import 'state.dart';
import 'theme.dart';

/// Lets services open screens, e.g. a tap on a reminder.
final GlobalKey<NavigatorState> appNavigator = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final AppState state = AppState();
  await state.load();
  void openStretch() {
    if (state.user != null) {
      appNavigator.currentState?.push(MaterialPageRoute<void>(builder: (BuildContext _) => const StretchScreen()));
    }
  }

  NotificationService.instance.onOpenStretch = openStretch;
  runApp(AppScope(notifier: state, child: const FitnessApp()));
  if (await NotificationService.instance.launchedFromStretch()) {
    WidgetsBinding.instance.addPostFrameCallback((Duration _) => openStretch());
  }
  // Plan the reminders for the next days every time the app starts.
  state.rescheduleReminders();
}

class FitnessApp extends StatelessWidget {
  const FitnessApp({super.key});

  @override
  Widget build(BuildContext context) {
    final AppState state = AppScope.of(context);
    return MaterialApp(
      title: 'Fitness Companion',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(
        Brightness.light,
        colors: AppColors.pick(Brightness.light, lightStyle: state.lightStyle, highContrast: state.highContrast),
      ),
      darkTheme: buildTheme(
        Brightness.dark,
        colors: AppColors.pick(Brightness.dark, darkStyle: state.darkStyle, highContrast: state.highContrast),
      ),
      themeMode: state.themeMode,
      navigatorKey: appNavigator,
      // Text size from the settings. High contrast adds a little on top.
      builder: (BuildContext context, Widget? child) {
        final double f = state.textScale * (state.highContrast ? 1.08 : 1.0);
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(f)),
          child: child ?? const SizedBox.shrink(),
        );
      },
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
    if (state.firstName.isEmpty) {
      return const NameScreen();
    }
    if (!state.featuresChosen) {
      return const FeatureChoiceScreen();
    }
    if (!state.body.done) {
      return const OnboardingScreen();
    }
    return const RootScreen();
  }
}
