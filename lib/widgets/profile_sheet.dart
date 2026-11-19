import 'package:flutter/material.dart';

import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../screens/settings_screen.dart';

/// Lime circle with the first letter of the name. Replaces the gear icon.
/// Tapping it opens the profile sheet with all settings.
class ProfileAvatar extends StatelessWidget {
  final double size;
  final VoidCallback? onTap;

  const ProfileAvatar({super.key, this.size = 44, this.onTap});

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    final AppState state = AppScope.of(context);
    final String name = state.firstName.trim();
    final Color ink = AppColors.of(context).onLime;
    final Widget inner = name.isEmpty
        ? Icon(Icons.person_outline, size: size * 0.55, color: ink)
        : Text(name.characters.first.toUpperCase(), style: heading(context, size * 0.5, color: ink));
    final Widget circle = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.lime,
        shape: BoxShape.circle,
        // Lime on a light background needs a dark edge (light head, sheet, high contrast).
        border: c.highContrast
            ? Border.all(color: c.text, width: c.borderWidth)
            : (c.accentEdge != null ? Border.all(color: c.accentEdge!, width: 1.5) : null),
      ),
      child: inner,
    );
    if (onTap == null) {
      return ExcludeSemantics(child: circle);
    }
    return Semantics(
      button: true,
      label: 'Profil und Einstellungen',
      child: InkResponse(
        onTap: onTap,
        radius: size * 0.7,
        // 48 px touch target around the circle.
        child: Padding(padding: const EdgeInsets.all(2), child: circle),
      ),
    );
  }
}

/// Opens the profile sheet. Each row closes the sheet and opens its settings page.
Future<void> showProfileSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x730D0E0F),
    builder: (BuildContext ctx) => const _ProfileSheet(),
  );
}

class _ProfileSheet extends StatelessWidget {
  const _ProfileSheet();

  void _open(BuildContext context, SettingsPage page) {
    final NavigatorState nav = Navigator.of(context);
    nav.pop();
    nav.push(MaterialPageRoute<void>(builder: (BuildContext _) => SettingsScreen(page: page)));
  }

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    final AppState state = AppScope.of(context);
    final double kg = state.lastBody?.weightKg ?? state.body.weightKg;
    final String name = state.firstName.isEmpty ? 'Profil' : state.firstName;

    Widget row(SettingsPage page, IconData icon, String title, String sub) {
      return InkWell(
        onTap: () => _open(context, page),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.border))),
          child: Row(
            children: <Widget>[
              Icon(icon, size: 22, color: c.text),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title, style: bodyStyle(context, size: 15, weight: FontWeight.w600)),
                    if (sub.isNotEmpty) Text(sub, style: bodyStyle(context, size: 12, color: c.text3)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: 22, color: c.text3),
            ],
          ),
        ),
      );
    }

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.85),
      decoration: BoxDecoration(
        color: c.bg,
        border: Border(top: BorderSide(color: c.highContrast ? c.text : c.lime, width: 3)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Center(child: Container(width: 44, height: 4, color: c.border)),
              const SizedBox(height: 14),
              InkWell(
                onTap: () => _open(context, SettingsPage.profile),
                child: Container(
                  padding: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.border))),
                  child: Row(
                    children: <Widget>[
                      const ProfileAvatar(size: 56),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(name.toUpperCase(), style: heading(context, 26)),
                            const SizedBox(height: 2),
                            Text(
                              '${formatKg(kg)} · ${state.weekGoal}× Training pro Woche',
                              style: bodyStyle(context, size: 13, color: c.text3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              row(SettingsPage.profile, Icons.person_outline, 'Profil', 'Name, Körperdaten, Konto'),
              row(SettingsPage.appearance, Icons.visibility_outlined, 'Darstellung', appearanceSummary(state)),
              row(SettingsPage.features, Icons.grid_view_outlined, 'Funktionen und Home', 'Coach, Tracking, Training, Blöcke'),
              row(SettingsPage.notifications, Icons.notifications_none, 'Benachrichtigungen',
                  state.pushEnabled ? 'Training, Dehnen, Körperdaten' : 'Alle aus'),
              row(SettingsPage.help, Icons.help_outline, 'Hilfe und Tutorials', 'Tour, Anleitungen, Trainingsstile'),
              row(SettingsPage.data, Icons.description_outlined, 'Daten und Rechtliches', 'Export, Löschen, Impressum'),
            ],
          ),
        ),
      ),
    );
  }
}

/// Short line such as "Hell · Weiß · Schrift normal".
String appearanceSummary(AppState s) {
  final String mode = s.themeMode == ThemeMode.light ? 'Hell' : (s.themeMode == ThemeMode.dark ? 'Dunkel' : 'System');
  const Map<String, String> light = <String, String>{'white': 'Weiß', 'stone': 'Stein', 'blue': 'Blau'};
  const Map<String, String> dark = <String, String>{'black': 'Schwarz', 'grey': 'Grau', 'blue': 'Blau'};
  final String style = s.themeMode == ThemeMode.dark ? (dark[s.darkStyle] ?? '') : (light[s.lightStyle] ?? '');
  final String size = s.textScale < 1 ? 'klein' : (s.textScale > 1 ? 'groß' : 'normal');
  return s.highContrast ? '$mode · Hoher Kontrast · Schrift $size' : '$mode · $style · Schrift $size';
}
