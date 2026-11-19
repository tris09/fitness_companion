import 'package:flutter/material.dart';

import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/settings_parts.dart';
import '../widgets/wheel_picker.dart';

/// Asks for body weight, height and age. The coach uses them.
/// Shown once after registration, and from the settings to change the values.
class OnboardingScreen extends StatefulWidget {
  /// True when opened from the settings: shows a back button.
  final bool editing;

  const OnboardingScreen({super.key, this.editing = false});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late BodyProfile _draft;
  bool _init = false;

  Future<void> _pick(String title, List<int> values, int initial, String unit, void Function(int v) set) async {
    final int? v = await showWheelPicker(context, title: title, values: values, initial: initial, label: (int x) => '$x $unit');
    if (v != null && mounted) {
      setState(() => set(v));
    }
  }

  Widget _row(String label, String value, VoidCallback onTap) {
    final AppColors c = AppColors.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: c.surface,
          border: Border.all(color: c.border),
          borderRadius: BorderRadius.circular(kRadius),
        ),
        child: Row(
          children: <Widget>[
            Expanded(child: SectionLabel(label)),
            Text(value, style: bodyStyle(context, size: 18, weight: FontWeight.w700)),
            const SizedBox(width: 8),
            Icon(Icons.unfold_more, size: 20, color: c.text2),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppState state = AppScope.of(context);
    final AppColors c = AppColors.of(context);
    if (!_init) {
      _draft = state.body.copy();
      _init = true;
    }
    final int weight10 = (_draft.weightKg * 2).round() * 5;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            PageHeader(
              kicker: widget.editing ? 'Profil' : 'Schritt 4 von 4',
              title: 'Körperdaten',
              showBack: widget.editing,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    'Dein Gewicht ist der Startpunkt für Verlauf und Gewichtsvorschläge. Die Daten bleiben auf deinem Gerät und gehen nur gekürzt mit einer Anfrage an den Coach.',
                    style: bodyStyle(context, size: 14, color: c.text2),
                  ),
                  const SizedBox(height: 20),
                  _row(
                    'Gewicht',
                    formatKg(weight10 / 10),
                    () async {
                      final int? v = await showWheelPicker(
                        context,
                        title: 'Gewicht',
                        values: numberRange(300, 2500, step: 5),
                        initial: weight10,
                        label: (int x) => formatKg(x / 10),
                      );
                      if (v != null && mounted) {
                        setState(() => _draft.weightKg = v / 10);
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  _row(
                    'Größe',
                    '${_draft.heightCm} cm',
                    () => _pick('Größe', numberRange(120, 230), _draft.heightCm, 'cm', (int v) => _draft.heightCm = v),
                  ),
                  const SizedBox(height: 10),
                  _row(
                    'Alter',
                    '${_draft.age} Jahre',
                    () => _pick('Alter', numberRange(14, 99), _draft.age, 'Jahre', (int v) => _draft.age = v),
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: widget.editing ? 'Speichern' : 'Weiter',
                    height: 64,
                    fontSize: 22,
                    onPressed: () {
                      state.saveBody(_draft);
                      if (widget.editing) {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                  if (!widget.editing) ...<Widget>[
                    const SizedBox(height: 10),
                    SecondaryButton(label: 'Abmelden', height: 48, fontSize: 17, onPressed: state.signOut),
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

/// First step after registration: which parts of the app the user wants.
/// Everything can be changed later in the settings.
class FeatureChoiceScreen extends StatefulWidget {
  const FeatureChoiceScreen({super.key});

  @override
  State<FeatureChoiceScreen> createState() => _FeatureChoiceScreenState();
}

class _FeatureChoiceScreenState extends State<FeatureChoiceScreen> {
  AppFeatures _f = AppFeatures();

  @override
  Widget build(BuildContext context) {
    final AppState state = AppScope.of(context);
    final AppColors c = AppColors.of(context);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const PageHeader(kicker: 'Schritt 3 von 4', title: 'Was möchtest du nutzen?'),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text('Du kannst alles später in den Einstellungen ändern.', style: bodyStyle(context, size: 14, color: c.text2)),
                  const SizedBox(height: 12),
                  FeatureToggles(value: _f, onChanged: (AppFeatures f) => setState(() => _f = f)),
                  const SizedBox(height: 20),
                  PrimaryButton(label: 'Weiter', height: 60, fontSize: 21, onPressed: () => state.setFeatures(_f)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// First page after login: asks for the first name, used in "Hi, Name".
/// Also opened from the settings to change the name.
class NameScreen extends StatefulWidget {
  final bool editing;

  const NameScreen({super.key, this.editing = false});

  @override
  State<NameScreen> createState() => _NameScreenState();
}

class _NameScreenState extends State<NameScreen> {
  final TextEditingController _name = TextEditingController();
  bool _init = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save(AppState state) {
    final String v = _name.text.trim();
    if (v.isEmpty) {
      setState(() => _error = 'Bitte gib deinen Vornamen ein.');
      return;
    }
    if (v.length > 30) {
      setState(() => _error = 'Der Name ist zu lang (höchstens 30 Zeichen).');
      return;
    }
    state.setFirstName(v);
    if (widget.editing) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppState state = AppScope.of(context);
    final AppColors c = AppColors.of(context);
    if (!_init) {
      _name.text = state.firstName;
      _init = true;
    }
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            PageHeader(
              kicker: widget.editing ? 'Profil' : 'Schritt 1 von 4',
              title: 'Wie heißt du?',
              showBack: widget.editing,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text('Dein Vorname steht oben auf Home.', style: bodyStyle(context, size: 14, color: c.text2)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _name,
                    autofocus: !widget.editing,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.done,
                    maxLength: 30,
                    style: bodyStyle(context, size: 17, weight: FontWeight.w600),
                    decoration: fieldDecoration(context, 'Vorname').copyWith(counterText: ''),
                    onChanged: (_) {
                      if (_error != null) {
                        setState(() => _error = null);
                      }
                    },
                    onSubmitted: (_) => _save(state),
                  ),
                  Reveal(
                    show: _error != null,
                    child: Padding(padding: const EdgeInsets.only(top: 10), child: ErrorNote(_error ?? '')),
                  ),
                  const SizedBox(height: 20),
                  PrimaryButton(
                    label: widget.editing ? 'Speichern' : 'Weiter',
                    height: 60,
                    fontSize: 21,
                    onPressed: () => _save(state),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Step 2 at registration: the look of the app. Every choice applies at once,
/// so the screen itself is the preview. All of it can be changed later in
/// Profil › Darstellung.
class ThemeChoiceScreen extends StatelessWidget {
  const ThemeChoiceScreen({super.key});

  static const List<(String, String, Brightness)> _styles = <(String, String, Brightness)>[
    ('white', 'Weiß', Brightness.light),
    ('stone', 'Stein', Brightness.light),
    ('blue', 'Blau', Brightness.light),
    ('black', 'Schwarz', Brightness.dark),
    ('grey', 'Grau', Brightness.dark),
    ('blue', 'Blau', Brightness.dark),
  ];

  @override
  Widget build(BuildContext context) {
    final AppState state = AppScope.of(context);
    final AppColors c = AppColors.of(context);
    final Brightness now = Theme.of(context).brightness;

    bool isOn((String, String, Brightness) s) {
      if (state.highContrast || s.$3 != now) {
        return false;
      }
      return s.$3 == Brightness.light ? state.lightStyle == s.$1 : state.darkStyle == s.$1;
    }

    void pick((String, String, Brightness) s) {
      if (s.$3 == Brightness.light) {
        state.setLightStyle(s.$1);
      } else {
        state.setDarkStyle(s.$1);
      }
      state.setHighContrast(false);
      // Picking a light or dark look also fixes the mode; "System" stays available above.
      if (state.themeMode != ThemeMode.system || s.$3 != now) {
        state.setThemeMode(s.$3 == Brightness.light ? ThemeMode.light : ThemeMode.dark);
      }
    }

    Widget modeChip(String label, ThemeMode m) {
      return InkWell(
        onTap: () => state.setThemeMode(m),
        child: ChipBox(text: label, selected: state.themeMode == m, height: 44),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const PageHeader(kicker: 'Schritt 2 von 4', title: 'Dein Look'),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text('Tippe ein Design an, die App wechselt sofort. Du kannst es später jederzeit ändern.',
                      style: bodyStyle(context, size: 14, color: c.text2)),
                  const SizedBox(height: 16),
                  const SectionLabel('Modus'),
                  const SizedBox(height: 8),
                  EvenGrid(columns: 3, children: <Widget>[
                    modeChip('Hell', ThemeMode.light),
                    modeChip('Dunkel', ThemeMode.dark),
                    modeChip('System', ThemeMode.system),
                  ]),
                  const SizedBox(height: 18),
                  const SectionLabel('Hell'),
                  const SizedBox(height: 8),
                  EvenGrid(columns: 3, children: <Widget>[
                    for (final (String, String, Brightness) s in _styles.where((e) => e.$3 == Brightness.light))
                      _ThemeCard(
                        label: s.$2,
                        colors: AppColors.pick(Brightness.light, lightStyle: s.$1),
                        selected: isOn(s),
                        onTap: () => pick(s),
                      ),
                  ]),
                  const SizedBox(height: 14),
                  const SectionLabel('Dunkel'),
                  const SizedBox(height: 8),
                  EvenGrid(columns: 3, children: <Widget>[
                    for (final (String, String, Brightness) s in _styles.where((e) => e.$3 == Brightness.dark))
                      _ThemeCard(
                        label: s.$2,
                        colors: AppColors.pick(Brightness.dark, darkStyle: s.$1),
                        selected: isOn(s),
                        onTap: () => pick(s),
                      ),
                  ]),
                  const SizedBox(height: 14),
                  SwitchRow(
                    title: 'Hoher Kontrast',
                    note: 'Schwarz/Weiß, dicke Ränder. Für Sehschwäche.',
                    value: state.highContrast,
                    onChanged: state.setHighContrast,
                  ),
                  const SizedBox(height: 10),
                  const SectionLabel('Schriftgröße'),
                  const SizedBox(height: 8),
                  EvenGrid(columns: 3, children: <Widget>[
                    InkWell(onTap: () => state.setTextScale(0.9), child: ChipBox(text: 'A−', selected: state.textScale < 1, height: 44)),
                    InkWell(onTap: () => state.setTextScale(1.0), child: ChipBox(text: 'A', selected: state.textScale == 1, height: 44)),
                    InkWell(onTap: () => state.setTextScale(1.15), child: ChipBox(text: 'A+', selected: state.textScale > 1, height: 44)),
                  ]),
                  const SizedBox(height: 18),
                  const AccentPicker(),
                  const SizedBox(height: 22),
                  PrimaryButton(label: 'Weiter', height: 60, fontSize: 21, onPressed: state.markThemeChosen),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small preview of one look: page, header with marker title, lime block and two cards.
class _ThemeCard extends StatelessWidget {
  final String label;
  final AppColors colors;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeCard({required this.label, required this.colors, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    final AppColors t = colors;
    final bool dark = t.isDark;
    Widget card() => Expanded(
          child: Container(
            height: 18,
            decoration: BoxDecoration(color: t.surface, border: Border.all(color: t.border)),
          ),
        );
    return Semantics(
      button: true,
      selected: selected,
      label: 'Design $label',
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: kFast,
          decoration: BoxDecoration(
            border: Border.all(color: selected ? c.text : c.outline, width: selected ? 2.5 : c.borderWidth),
            borderRadius: BorderRadius.circular(kRadius),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(
                height: 96,
                color: t.bg,
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    // Header: dark bar in dark themes, marker title in light themes.
                    Container(
                      height: 20,
                      color: dark ? (t.band ?? t.surface) : t.bg,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Container(
                        width: 34,
                        height: 7,
                        color: dark ? t.text : t.lime,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(height: 22, color: t.lime),
                    const SizedBox(height: 6),
                    Row(children: <Widget>[card(), const SizedBox(width: 5), card()]),
                  ],
                ),
              ),
              Container(
                color: c.control,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    if (selected) ...<Widget>[Icon(Icons.check, size: 16, color: c.text), const SizedBox(width: 4)],
                    Flexible(child: Text(label, overflow: TextOverflow.ellipsis, style: bodyStyle(context, size: 13, weight: FontWeight.w700))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
