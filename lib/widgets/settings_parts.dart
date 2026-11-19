import 'package:flutter/material.dart';

import '../models.dart';
import '../state.dart';
import '../theme.dart';
import 'common.dart';

/// A row with a title, a short note and a switch.
class SwitchRow extends StatelessWidget {
  final String title;
  final String note;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const SwitchRow({super.key, required this.title, this.note = '', required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: bodyStyle(context, size: 15, weight: FontWeight.w600, color: onChanged == null ? c.text3 : c.text)),
                if (note.isNotEmpty) Text(note, style: bodyStyle(context, size: 12, color: c.text3)),
              ],
            ),
          ),
          // Always-on rows keep the normal look and are only faded, so every switch looks the same.
          Opacity(
            opacity: onChanged == null ? 0.5 : 1,
            child: Switch(value: value, onChanged: onChanged),
          ),
        ],
      ),
    );
  }
}

/// Choice of the parts of the app. Used at registration and in the settings.
class FeatureToggles extends StatelessWidget {
  final AppFeatures value;
  final ValueChanged<AppFeatures> onChanged;

  const FeatureToggles({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    void set(void Function(AppFeatures f) change) {
      final AppFeatures f = value.copy();
      change(f);
      onChanged(f);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SwitchRow(title: 'Trainingsplanung', note: 'Kalender, Pläne, Timer · immer an', value: true, onChanged: null),
        SwitchRow(title: 'AI-Coach', note: 'Pläne generieren, Chat', value: value.coach, onChanged: (bool v) => set((AppFeatures f) => f.coach = v)),
        SwitchRow(
          title: 'Körperdaten-Tracking',
          note: 'Gewicht und Maße als Verlauf',
          value: value.tracking,
          onChanged: (bool v) => set((AppFeatures f) => f.tracking = v),
        ),
        SwitchRow(title: 'Dehnplan', note: 'Kurze Dehnpausen per Push', value: value.stretch, onChanged: (bool v) => set((AppFeatures f) => f.stretch = v)),
        SwitchRow(title: 'Essen und Einkauf', note: 'Einkaufslisten, Tab „Essen“', value: value.food, onChanged: (bool v) => set((AppFeatures f) => f.food = v)),
        SwitchRow(title: 'Fitness-News', note: 'Neuigkeiten unten auf Home', value: value.news, onChanged: (bool v) => set((AppFeatures f) => f.news = v)),
      ],
    );
  }
}

/// Mode, background style, high contrast and text size.
class AppearanceSettings extends StatelessWidget {
  const AppearanceSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final AppState state = AppScope.of(context);
    Widget chip(String label, bool selected, VoidCallback onTap) => Expanded(
          child: InkWell(onTap: onTap, child: ChipBox(text: label, selected: selected, height: 44)),
        );
    Widget rowOf(List<Widget> chips) {
      final List<Widget> out = <Widget>[];
      for (int i = 0; i < chips.length; i++) {
        if (i > 0) {
          out.add(const SizedBox(width: 8));
        }
        out.add(chips[i]);
      }
      return Row(children: out);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SectionLabel('Modus'),
        const SizedBox(height: 8),
        rowOf(<Widget>[
          chip('System', state.themeMode == ThemeMode.system, () => state.setThemeMode(ThemeMode.system)),
          chip('Hell', state.themeMode == ThemeMode.light, () => state.setThemeMode(ThemeMode.light)),
          chip('Dunkel', state.themeMode == ThemeMode.dark, () => state.setThemeMode(ThemeMode.dark)),
        ]),
        const SizedBox(height: 14),
        const SectionLabel('Hintergrund hell'),
        const SizedBox(height: 8),
        rowOf(<Widget>[
          chip('Weiß', state.lightStyle == 'white', () => state.setLightStyle('white')),
          chip('Stein', state.lightStyle == 'stone', () => state.setLightStyle('stone')),
          chip('Blau', state.lightStyle == 'blue', () => state.setLightStyle('blue')),
        ]),
        const SizedBox(height: 14),
        const SectionLabel('Hintergrund dunkel'),
        const SizedBox(height: 8),
        rowOf(<Widget>[
          chip('Schwarz', state.darkStyle == 'black', () => state.setDarkStyle('black')),
          chip('Grau', state.darkStyle == 'grey', () => state.setDarkStyle('grey')),
          chip('Blau', state.darkStyle == 'blue', () => state.setDarkStyle('blue')),
        ]),
        const SizedBox(height: 10),
        SwitchRow(
          title: 'Hoher Kontrast',
          note: 'Schwarz/Weiß, dicke Ränder, ohne Titelleiste. Für Sehschwäche.',
          value: state.highContrast,
          onChanged: state.setHighContrast,
        ),
        const SizedBox(height: 6),
        const SectionLabel('Schriftgröße'),
        const SizedBox(height: 8),
        rowOf(<Widget>[
          chip('A−', state.textScale < 1, () => state.setTextScale(0.9)),
          chip('A', state.textScale == 1, () => state.setTextScale(1.0)),
          chip('A+', state.textScale > 1, () => state.setTextScale(1.15)),
        ]),
      ],
    );
  }
}
