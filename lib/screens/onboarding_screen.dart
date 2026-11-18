import 'package:flutter/material.dart';

import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';
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
    final int weightWhole = _draft.weightKg.round();
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            PageHeader(
              kicker: widget.editing ? 'Profil' : 'Fast geschafft',
              title: 'Körperdaten',
              showBack: widget.editing,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    'Damit der Coach passende Trainings vorschlagen kann. Die Daten bleiben auf deinem Gerät und gehen nur mit deiner Anfrage an den Coach.',
                    style: bodyStyle(context, size: 14, color: c.text2),
                  ),
                  const SizedBox(height: 20),
                  _row(
                    'Gewicht',
                    '$weightWhole kg',
                    () => _pick('Gewicht', numberRange(30, 250), weightWhole, 'kg', (int v) => _draft.weightKg = v.toDouble()),
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
