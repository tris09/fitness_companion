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
        const SizedBox(height: 18),
        const AccentPicker(),
      ],
    );
  }
}

/// Fixed accent colours that fit the graphite and white backgrounds.
/// No red: red is the error colour.
const List<(String, Color)> kAccentPalette = <(String, Color)>[
  ('Lime', Color(0xFFC6FF00)),
  ('Mint', Color(0xFF3DF2A5)),
  ('Cyan', Color(0xFF22D3EE)),
  ('Blau', Color(0xFF4C8DFF)),
  ('Violett', Color(0xFFA78BFA)),
  ('Pink', Color(0xFFFF5CA8)),
  ('Orange', Color(0xFFFF8A1F)),
  ('Gelb', Color(0xFFFFD60A)),
];

/// Accent colour: palette plus a free colour picker. Applies at once.
class AccentPicker extends StatelessWidget {
  const AccentPicker({super.key});

  @override
  Widget build(BuildContext context) {
    final AppState state = AppScope.of(context);
    final AppColors c = AppColors.of(context);
    final int current = state.accent.toARGB32();
    final bool custom = !kAccentPalette.any(((String, Color) p) => p.$2.toARGB32() == current);

    Widget swatch(Color color, String label, bool selected, VoidCallback onTap, {Widget? child}) {
      return Semantics(
        button: true,
        selected: selected,
        label: 'Akzentfarbe $label',
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: AnimatedContainer(
            duration: kFast,
            width: 48,
            height: 48,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: selected ? c.text : Colors.transparent, width: 2.5),
            ),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: c.outline),
              ),
              child: child ??
                  (selected
                      ? Icon(Icons.check, size: 20, color: color.computeLuminance() > 0.35 ? const Color(0xFF0D0E0F) : Colors.white)
                      : null),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SectionLabel('Akzentfarbe'),
        const SizedBox(height: 4),
        Text(
          'Färbt Buttons, Auswahl, den heutigen Tag und die Trainingskarte.',
          style: bodyStyle(context, size: 13, color: c.text2),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final (String label, Color color) in kAccentPalette)
              swatch(color, label, color.toARGB32() == current, () => state.setAccent(color)),
            swatch(
              custom ? state.accent : c.control,
              'Eigene Farbe',
              custom,
              () => showAccentDialog(context),
              child: custom ? null : Icon(Icons.colorize, size: 20, color: c.text),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          custom ? 'Eigene Farbe #${hexOf(state.accent)}' : kAccentPalette.firstWhere(((String, Color) p) => p.$2.toARGB32() == current).$1,
          style: bodyStyle(context, size: 13, weight: FontWeight.w600),
        ),
      ],
    );
  }
}

String hexOf(Color c) => (c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase();

/// Free colour picker: hue, saturation and brightness sliders, hex field and a preview.
Future<void> showAccentDialog(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (BuildContext ctx) => const _AccentSheet(),
  );
}

class _AccentSheet extends StatefulWidget {
  const _AccentSheet();

  @override
  State<_AccentSheet> createState() => _AccentSheetState();
}

class _AccentSheetState extends State<_AccentSheet> {
  late HSVColor _hsv;
  final TextEditingController _hex = TextEditingController();
  bool _init = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_init) {
      _hsv = HSVColor.fromColor(AppScope.of(context).accent);
      _hex.text = hexOf(_hsv.toColor());
      _init = true;
    }
  }

  @override
  void dispose() {
    _hex.dispose();
    super.dispose();
  }

  void _set(HSVColor v) {
    setState(() {
      _hsv = v;
      _hex.text = hexOf(v.toColor());
      _error = null;
    });
  }

  void _fromHex(String v) {
    final String t = v.trim().replaceAll('#', '');
    final int? n = t.length == 6 ? int.tryParse(t, radix: 16) : null;
    setState(() {
      if (n == null) {
        _error = 'Bitte 6 Zeichen eingeben, z. B. C6FF00.';
      } else {
        _hsv = HSVColor.fromColor(Color(0xFF000000 | n));
        _error = null;
      }
    });
  }

  Widget _slider(String label, double value, double max, List<Color> track, ValueChanged<double> onChanged) {
    final AppColors c = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SectionLabel(label),
        const SizedBox(height: 6),
        Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Container(
              height: 14,
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: track),
                border: Border.all(color: c.outline),
                borderRadius: BorderRadius.circular(7),
              ),
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 0,
                activeTrackColor: Colors.transparent,
                inactiveTrackColor: Colors.transparent,
                thumbColor: c.text,
                overlayColor: c.text.withValues(alpha: 0.12),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
              ),
              child: Slider(value: value, max: max, onChanged: onChanged),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    final Color color = _hsv.toColor();
    final Color on = color.computeLuminance() > 0.35 ? const Color(0xFF0D0E0F) : Colors.white;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text('EIGENE FARBE', style: heading(context, 28)),
            const SizedBox(height: 12),
            // Preview: a filled button and a selected chip in the new colour.
            Container(
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color,
                border: Border.all(color: c.accentEdge ?? color, width: 1.5),
                borderRadius: BorderRadius.circular(kRadius),
              ),
              child: Text('VORSCHAU', style: heading(context, 22, color: on)),
            ),
            const SizedBox(height: 16),
            _slider('Farbton', _hsv.hue, 360, <Color>[
              for (int h = 0; h <= 360; h += 60) HSVColor.fromAHSV(1, h.toDouble(), 1, 1).toColor(),
            ], (double v) => _set(_hsv.withHue(v))),
            _slider('Sättigung', _hsv.saturation, 1, <Color>[
              _hsv.withSaturation(0).toColor(),
              _hsv.withSaturation(1).toColor(),
            ], (double v) => _set(_hsv.withSaturation(v))),
            _slider('Helligkeit', _hsv.value, 1, <Color>[
              _hsv.withValue(0).toColor(),
              _hsv.withValue(1).toColor(),
            ], (double v) => _set(_hsv.withValue(v))),
            const SizedBox(height: 8),
            TextField(
              controller: _hex,
              maxLength: 7,
              style: bodyStyle(context, size: 16, weight: FontWeight.w600),
              decoration: fieldDecoration(context, 'Hex-Code, z. B. C6FF00').copyWith(counterText: '', prefixText: '#'),
              onSubmitted: _fromHex,
              onChanged: (String v) {
                if (v.replaceAll('#', '').length == 6) {
                  _fromHex(v);
                }
              },
            ),
            Reveal(show: _error != null, child: Padding(padding: const EdgeInsets.only(top: 8), child: ErrorNote(_error ?? ''))),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Übernehmen',
              height: 56,
              fontSize: 20,
              onPressed: () {
                AppScope.of(context).setAccent(color);
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: 8),
            SecondaryButton(
              label: 'Zurück zu Lime',
              onPressed: () {
                AppScope.of(context).setAccent(AppColors.defaultAccent);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}
