import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models.dart';
import '../state.dart';
import '../tutorials.dart';
import '../widgets/tutorial_dialog.dart';
import 'legal_screen.dart';
import 'stretch_screen.dart';
import 'wiki_screen.dart';
import 'onboarding_screen.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/settings_parts.dart';
import 'home_edit_screen.dart';

/// Pages of the settings. Reached from the profile sheet (tap on the initial on Home).
enum SettingsPage { profile, appearance, features, notifications, help, data }

/// One settings page as a normal screen. A screen follows the theme at once when
/// the user switches between light and dark. (A bottom sheet keeps the old theme.)
class SettingsScreen extends StatelessWidget {
  final SettingsPage page;

  const SettingsScreen({super.key, this.page = SettingsPage.profile});

  static const Map<SettingsPage, String> _titles = <SettingsPage, String>{
    SettingsPage.profile: 'Profil',
    SettingsPage.appearance: 'Darstellung',
    SettingsPage.features: 'Funktionen',
    SettingsPage.notifications: 'Push',
    SettingsPage.help: 'Hilfe',
    SettingsPage.data: 'Daten',
  };

  /// Leaves all settings pages and returns to the tabs.
  static void _toTabs(BuildContext context) => Navigator.of(context).popUntil((Route<dynamic> r) => r.isFirst);

  @override
  Widget build(BuildContext context) {
    final List<Widget> body = switch (page) {
      SettingsPage.profile => _profile(context),
      SettingsPage.appearance => const <Widget>[AppearanceSettings()],
      SettingsPage.features => _features(context),
      SettingsPage.notifications => _notifications(context),
      SettingsPage.help => _help(context),
      SettingsPage.data => _data(context),
    };
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            PageHeader(kicker: 'Einstellungen', title: _titles[page]!, showBack: true),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: body),
            ),
          ],
        ),
      ),
    );
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (BuildContext _) => screen));
  }

  List<Widget> _profile(BuildContext context) {
    final AppState state = AppScope.of(context);
    final AppColors c = AppColors.of(context);
    final bool admin = state.user?.isAdmin ?? false;
    final double kg = state.lastBody?.weightKg ?? state.body.weightKg;
    return <Widget>[
      const SectionLabel('Name'),
      const SizedBox(height: 8),
      SecondaryButton(
        label: state.firstName.isEmpty ? 'Name eintragen' : 'Name ändern (${state.firstName})',
        onPressed: () => _push(context, const NameScreen(editing: true)),
      ),
      const SizedBox(height: 24),
      const SectionLabel('Körperdaten'),
      const SizedBox(height: 4),
      Text(
        '${formatKg(kg)} · ${state.body.heightCm} cm · ${state.body.age} Jahre',
        style: bodyStyle(context, size: 15, weight: FontWeight.w600),
      ),
      const SizedBox(height: 8),
      SecondaryButton(label: 'Körperdaten ändern', onPressed: () => _push(context, const OnboardingScreen(editing: true))),
      const SizedBox(height: 24),
      const SectionLabel('Konto'),
      const SizedBox(height: 8),
      Row(
        children: <Widget>[
          Expanded(
            child: Text(
              (state.user?.isLocal ?? false) ? 'Lokal, ohne Konto' : (state.user?.email ?? ''),
              style: bodyStyle(context, size: 15, weight: FontWeight.w600, color: c.text),
            ),
          ),
          if (admin) const ChipBox(text: 'Admin', selected: true, height: 32, showCheck: false),
        ],
      ),
      const SizedBox(height: 12),
      SecondaryButton(
        label: 'Abmelden',
        onPressed: () {
          _toTabs(context);
          state.signOut();
        },
      ),
    ];
  }

  List<Widget> _features(BuildContext context) {
    final AppState state = AppScope.of(context);
    final AppColors c = AppColors.of(context);
    return <Widget>[
      const SectionLabel('Funktionen'),
      const SizedBox(height: 4),
      Text('Was du bei der Registrierung gewählt hast. Jederzeit änderbar.', style: bodyStyle(context, size: 13, color: c.text2)),
      FeatureToggles(value: state.features, onChanged: state.setFeatures),
      const SizedBox(height: 24),
      const SectionLabel('Training'),
      SwitchRow(title: 'Nach Gewichten fragen', note: 'Nach jedem Training', value: state.askWeights, onChanged: state.setAskWeights),
      SwitchRow(title: 'Aufwärmen und Cooldown', note: 'Je 2 Dehnübungen', value: state.warmup, onChanged: state.setWarmup),
      const SizedBox(height: 24),
      const SectionLabel('Home'),
      const SizedBox(height: 8),
      SecondaryButton(label: 'Home anpassen', onPressed: () => _push(context, const HomeEditScreen())),
      const SizedBox(height: 8),
      SecondaryButton(
        label: 'Home zurücksetzen',
        onPressed: () {
          state.resetHome();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Home ist wieder in der Standard-Reihenfolge.')));
        },
      ),
    ];
  }

  List<Widget> _notifications(BuildContext context) {
    final AppState state = AppScope.of(context);
    return <Widget>[
      SwitchRow(title: 'Alle Push-Nachrichten', note: 'Hauptschalter', value: state.pushEnabled, onChanged: state.setPushEnabled),
      SwitchRow(
        title: 'Training',
        note: '30 Minuten vor einer Einheit mit Uhrzeit',
        value: state.trainingReminders,
        onChanged: state.pushEnabled ? state.setTrainingReminders : null,
      ),
      SwitchRow(
        title: 'Körperdaten',
        note: 'Montags 08:00, Gewicht eintragen',
        value: state.bodyReminder,
        onChanged: state.pushEnabled && state.features.tracking ? state.setBodyReminder : null,
      ),
      const SizedBox(height: 12),
      SecondaryButton(
        label: 'Dehn-Erinnerungen',
        onPressed: state.features.stretch ? () => _push(context, const StretchScreen()) : null,
      ),
    ];
  }

  List<Widget> _help(BuildContext context) {
    final AppState state = AppScope.of(context);
    return <Widget>[
      SecondaryButton(label: 'Willkommens-Tour ansehen', onPressed: () => showTutorial(context, welcomeTutorial)),
      const SizedBox(height: 8),
      if (state.features.coach) ...<Widget>[
        SecondaryButton(label: 'Anleitung: API-Schlüssel', onPressed: () => showTutorial(context, geminiKeyTutorial)),
        const SizedBox(height: 8),
      ],
      SecondaryButton(label: 'Trainingsstile erklärt', onPressed: () => _push(context, const WikiScreen())),
    ];
  }

  List<Widget> _data(BuildContext context) {
    final AppState state = AppScope.of(context);
    final AppColors c = AppColors.of(context);
    final bool admin = state.user?.isAdmin ?? false;
    return <Widget>[
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
      SecondaryButton(label: 'Datenschutz und Impressum', onPressed: () => _push(context, const LegalScreen())),
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
            _toTabs(context);
          },
        ),
      ],
    ];
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
      _toTabs(context);
      await state.deleteEverything();
    }
  }
}
