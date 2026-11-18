import 'package:flutter/material.dart';

import '../catalog.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../training_memory.dart';
import '../widgets/common.dart';
import '../widgets/wheel_picker.dart';

/// Shown after a workout. Optionally asks for the weights that were used.
class SuccessScreen extends StatefulWidget {
  final Plan plan;

  const SuccessScreen({super.key, required this.plan});

  @override
  State<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen> {
  /// Entered weights in kg per exercise id. Only these are saved.
  final Map<String, double> _kg = <String, double>{};
  final Map<String, String> _feel = <String, String>{};

  List<PlanItem> _weighted() {
    final Set<String> seen = <String>{};
    return widget.plan.items.where((PlanItem i) => usesWeight(exerciseById(i.exerciseId)) && seen.add(i.exerciseId)).toList();
  }

  Future<void> _pick(AppState state, PlanItem item) async {
    final double start = _kg[item.exerciseId] ?? state.suggestedWeight(item.exerciseId) ?? 20;
    // Values in steps of 0,5 kg, from 0 to 300 kg.
    final int? v = await showWheelPicker(
      context,
      title: exerciseById(item.exerciseId).name,
      values: numberRange(0, 600),
      initial: (start * 2).round().clamp(0, 600),
      label: (int x) => formatKg(x / 2),
    );
    if (v != null && mounted) {
      setState(() => _kg[item.exerciseId] = v / 2);
    }
  }

  void _finish(AppState state) {
    if (_kg.isNotEmpty) {
      final DateTime now = DateTime.now();
      state.addWeights(<String, WeightEntry>{
        for (final PlanItem i in _weighted())
          if (_kg[i.exerciseId] != null)
            i.exerciseId: WeightEntry(date: now, kg: _kg[i.exerciseId]!, reps: i.reps, feel: _feel[i.exerciseId] ?? ''),
      });
    }
    Navigator.of(context).popUntil((Route<dynamic> r) => r.isFirst);
  }

  Widget _row(AppState state, PlanItem item) {
    final AppColors c = AppColors.of(context);
    final Exercise ex = exerciseById(item.exerciseId);
    final double? entered = _kg[item.exerciseId];
    final double? tip = state.suggestedWeight(item.exerciseId);
    final WeightEntry? last = state.lastWeight(item.exerciseId);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: c.border))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(ex.name.toUpperCase(), style: heading(context, 20)),
                    Text(
                      last == null ? '${item.sets} × ${item.reps} · noch kein Gewicht' : '${item.sets} × ${item.reps} · zuletzt ${formatKg(last.kg)}',
                      style: bodyStyle(context, size: 13, color: c.text2),
                    ),
                    if (entered != null && state.records[item.exerciseId] != null && entered > state.records[item.exerciseId]!)
                      Text('Neuer Rekord!', style: bodyStyle(context, size: 13, weight: FontWeight.w700, color: c.accentText)),
                  ],
                ),
              ),
              InkWell(
                onTap: () => _pick(state, item),
                child: ChipBox(
                  text: entered != null ? formatKg(entered) : (tip != null ? 'Vorschlag ${formatKg(tip)}' : 'Gewicht'),
                  selected: entered != null,
                  height: 44,
                  showCheck: false,
                ),
              ),
            ],
          ),
          AnimatedSize(
            duration: kFast,
            curve: kEase,
            alignment: Alignment.topCenter,
            child: entered == null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: EvenGrid(
                      columns: 3,
                      children: <Widget>[
                        for (final String f in const <String>['leicht', 'passt', 'schwer'])
                          InkWell(
                            onTap: () => setState(() => _feel[item.exerciseId] = _feel[item.exerciseId] == f ? '' : f),
                            child: ChipBox(text: f == 'leicht' ? 'Zu leicht' : (f == 'passt' ? 'Passt' : 'Zu schwer'), selected: _feel[item.exerciseId] == f, height: 40),
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    final AppState state = AppScope.of(context);
    final List<PlanItem> weighted = state.askWeights ? _weighted() : <PlanItem>[];
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
          children: <Widget>[
            Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: c.accent, width: 4)),
                child: Icon(Icons.check, size: 72, color: c.accentText),
              ),
            ),
            const SizedBox(height: 20),
            Center(child: SectionLabel('Training abgeschlossen', color: c.accentText)),
            const SizedBox(height: 8),
            Center(child: Text('GESCHAFFT!', style: heading(context, 64))),
            const SizedBox(height: 6),
            Center(
              child: Text('${widget.plan.name} · ${widget.plan.items.length} Übungen', style: bodyStyle(context, size: 15, color: c.text2)),
            ),
            if (weighted.isNotEmpty) ...<Widget>[
              const SizedBox(height: 28),
              const SectionLabel('Gewichte eintragen · optional'),
              const SizedBox(height: 4),
              Text(
                'Tippe auf ein Gewicht. Damit schlagen App und Coach beim nächsten Mal das passende Gewicht vor.',
                style: bodyStyle(context, size: 13, color: c.text2),
              ),
              const SizedBox(height: 8),
              for (final PlanItem i in weighted) _row(state, i),
            ],
            const SizedBox(height: 24),
            PrimaryButton(
              label: _kg.isEmpty ? 'Fertig' : 'Speichern & fertig',
              height: 64,
              fontSize: 22,
              onPressed: () => _finish(state),
            ),
          ],
        ),
      ),
    );
  }
}
