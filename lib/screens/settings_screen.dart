import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state.dart';
import 'legal_screen.dart';
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
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'Aufwärmen und Cooldown mit je 2 Dehnübungen',
                          style: bodyStyle(context, size: 15, weight: FontWeight.w600),
                        ),
                      ),
                      Switch(value: state.warmup, onChanged: state.setWarmup),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const SectionLabel('Konto'),
                  const SizedBox(height: 8),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          (state.user?.isLocal ?? false) ? 'Lokal, ohne Konto' : (state.user?.email ?? ''),
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
                  const SizedBox(height: 24),
                  const SectionLabel('Deine Daten'),
                  const SizedBox(height: 8),
                  SecondaryButton(
                    label: 'Daten exportieren',
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: state.exportJson()));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Alle Daten sind in der Zwischenablage. Füge sie z. B. in eine Notiz ein.')),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  SecondaryButton(label: 'Alle Daten löschen', onPressed: () => _confirmDelete(context, state)),
                  const SizedBox(height: 24),
                  const SectionLabel('Rechtliches'),
                  const SizedBox(height: 8),
                  SecondaryButton(
                    label: 'Datenschutz und Impressum',
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute<void>(builder: (BuildContext _) => const LegalScreen()));
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

  /// Two steps: open the question, then confirm. Keeping is the main button.
  Future<void> _confirmDelete(BuildContext context, AppState state) async {
    final AppColors c = AppColors.of(context);
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: c.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadius), side: BorderSide(color: c.border)),
          title: Text('ALLES LÖSCHEN?', style: heading(ctx, 28)),
          content: Text(
            'Pläne, Verlauf, Gewichte, Chat, Einkaufslisten, Einstellungen, API-Schlüssel und lokale Konten '
            'werden von diesem Handy gelöscht. Das lässt sich nicht rückgängig machen. '
            'Exportiere vorher deine Daten, wenn du sie behalten willst.',
            style: bodyStyle(ctx, size: 15, color: c.text2),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                PrimaryButton(label: 'Behalten', height: 52, onPressed: () => Navigator.of(ctx).pop(false)),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: Text('Ja, alles endgültig löschen', style: bodyStyle(ctx, size: 14, weight: FontWeight.w600, color: c.text2)),
                ),
              ],
            ),
          ],
        );
      },
    );
    if (ok == true && context.mounted) {
      Navigator.of(context).pop();
      await state.deleteEverything();
    }
  }
}
