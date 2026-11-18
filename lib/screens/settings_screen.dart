import 'package:flutter/material.dart';

import '../state.dart';
import 'onboarding_screen.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Settings as a normal screen. A screen follows the theme at once when the
/// user switches between light and dark. (A bottom sheet keeps the old theme.)
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    final AppState state = AppScope.of(context);
    final bool admin = state.user?.isAdmin ?? false;

    Widget option(String label, ThemeMode mode) {
      return Expanded(
        child: InkWell(
          onTap: () => state.setThemeMode(mode),
          child: ChipBox(text: label, selected: state.themeMode == mode, height: 48),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const PageHeader(kicker: 'App', title: 'Einstellungen', showBack: true),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const SectionLabel('Darstellung'),
                  const SizedBox(height: 8),
                  Row(
                    children: <Widget>[
                      option('System', ThemeMode.system),
                      const SizedBox(width: 8),
                      option('Hell', ThemeMode.light),
                      const SizedBox(width: 8),
                      option('Dunkel', ThemeMode.dark),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const SectionLabel('Training'),
                  const SizedBox(height: 4),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'Nach dem Training nach Gewichten fragen',
                          style: bodyStyle(context, size: 15, weight: FontWeight.w600),
                        ),
                      ),
                      Switch(value: state.askWeights, onChanged: state.setAskWeights),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const SectionLabel('Konto'),
                  const SizedBox(height: 8),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          state.user?.email ?? '',
                          style: bodyStyle(context, size: 15, weight: FontWeight.w600),
                        ),
                      ),
                      if (admin) const ChipBox(text: 'Admin', selected: true, height: 32, showCheck: false),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SecondaryButton(
                    label: 'Körperdaten ändern',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (BuildContext _) => const OnboardingScreen(editing: true)),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  SecondaryButton(
                    label: 'Abmelden',
                    onPressed: () {
                      Navigator.of(context).pop();
                      state.signOut();
                    },
                  ),
                  if (admin) ...<Widget>[
                    const SizedBox(height: 24),
                    const SectionLabel('Admin'),
                    const SizedBox(height: 8),
                    Text(
                      'Setzt Pläne, Dehn-Einstellungen und die Coach-Einrichtung auf den Anfangszustand zurück.',
                      style: bodyStyle(context, size: 13, color: c.text2),
                    ),
                    const SizedBox(height: 10),
                    SecondaryButton(
                      label: 'App-Daten zurücksetzen',
                      onPressed: () {
                        state.resetData();
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
