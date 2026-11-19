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
              kicker: widget.editing ? 'Profil' : 'Schritt 3 von 3',
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
            const PageHeader(kicker: 'Schritt 2 von 3', title: 'Was möchtest du nutzen?'),
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
              kicker: widget.editing ? 'Profil' : 'Schritt 1 von 3',
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
