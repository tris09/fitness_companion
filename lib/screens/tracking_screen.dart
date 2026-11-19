import 'package:flutter/material.dart';

import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/settings_parts.dart';
import '../widgets/wheel_picker.dart';
import 'progress_screen.dart';

/// Body weight and optional measurements. All entries stay 6 months.
class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  late int _kg10;
  int? _fat10;
  int? _waist;
  bool _init = false;

  Future<void> _pick(String title, List<int> values, int initial, String Function(int) label, void Function(int) set) async {
    final int? v = await showWheelPicker(context, title: title, values: values, initial: initial, label: label);
    if (v != null && mounted) {
      setState(() => set(v));
    }
  }

  Widget _row(String label, String value, VoidCallback onTap, {VoidCallback? onClear}) {
    final AppColors c = AppColors.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: c.surface,
          border: Border.all(color: c.border, width: c.borderWidth),
          borderRadius: BorderRadius.circular(kRadius),
        ),
        child: Row(
          children: <Widget>[
            Expanded(child: SectionLabel(label)),
            Text(value, style: bodyStyle(context, size: 18, weight: FontWeight.w700)),
            if (onClear != null)
              IconButton(tooltip: 'Leeren', onPressed: onClear, icon: Icon(Icons.close, size: 18, color: c.text2))
            else
              Padding(padding: const EdgeInsets.only(left: 8), child: Icon(Icons.unfold_more, size: 20, color: c.text2)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    final AppState state = AppScope.of(context);
    if (!_init) {
      final BodyEntry? last = state.lastBody;
      _kg10 = ((last?.weightKg ?? state.body.weightKg) * 10).round();
      _init = true;
    }
    final List<BodyEntry> log = state.bodyLog.reversed.toList();
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const PageHeader(kicker: 'Tracking', title: 'Körperdaten', showBack: true),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text('Einmal pro Woche reicht. Am besten morgens, unter gleichen Bedingungen.',
                      style: bodyStyle(context, size: 14, color: c.text2)),
                  const SizedBox(height: 16),
                  _row('Gewicht', formatKg(_kg10 / 10), () {
                    _pick('Gewicht', numberRange(300, 2500), _kg10, (int v) => formatKg(v / 10), (int v) => _kg10 = v);
                  }),
                  const SizedBox(height: 8),
                  _row(
                    'Körperfett · optional',
                    _fat10 == null ? '–' : '${(_fat10! / 10).toStringAsFixed(1).replaceAll('.', ',')} %',
                    () => _pick('Körperfett', numberRange(30, 600), _fat10 ?? 200,
                        (int v) => '${(v / 10).toStringAsFixed(1).replaceAll('.', ',')} %', (int v) => _fat10 = v),
                    onClear: _fat10 == null ? null : () => setState(() => _fat10 = null),
                  ),
                  const SizedBox(height: 8),
                  _row(
                    'Taille · optional',
                    _waist == null ? '–' : '$_waist cm',
                    () => _pick('Taille', numberRange(50, 180), _waist ?? 85, (int v) => '$v cm', (int v) => _waist = v),
                    onClear: _waist == null ? null : () => setState(() => _waist = null),
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: 'Speichern',
                    onPressed: () {
                      state.logBody(BodyEntry(
                        date: DateTime.now(),
                        weightKg: _kg10 / 10,
                        fatPercent: _fat10 == null ? null : _fat10! / 10,
                        waistCm: _waist?.toDouble(),
                      ));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gespeichert.')));
                    },
                  ),
                  const SizedBox(height: 16),
                  SwitchRow(
                    title: 'Wöchentliche Erinnerung',
                    note: 'Montags 08:00 per Push · Kachel zeigt „Fällig“',
                    value: state.bodyReminder,
                    onChanged: state.pushEnabled ? state.setBodyReminder : null,
                  ),
                  const SizedBox(height: 16),
                  if (state.bodyLog.length >= 2) ...<Widget>[
                    const SectionLabel('Verlauf · 6 Monate'),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 160,
                      child: CustomPaint(
                        painter: LineChart(
                          values: state.bodyLog.map((BodyEntry e) => e.weightKg).toList(),
                          line: c.accentText,
                          grid: c.border,
                          label: c.text2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (log.isNotEmpty) const SectionLabel('Einträge'),
                  for (final BodyEntry e in log)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(border: Border(top: BorderSide(color: c.border))),
                      child: Row(
                        children: <Widget>[
                          SizedBox(width: 70, child: Text('${e.date.day}.${e.date.month}.', style: bodyStyle(context, size: 14, color: c.text2))),
                          Expanded(
                            child: Text(
                              <String>[
                                formatKg(e.weightKg),
                                if (e.fatPercent != null) '${e.fatPercent!.toStringAsFixed(1).replaceAll('.', ',')} %',
                                if (e.waistCm != null) '${e.waistCm!.round()} cm',
                              ].join(' · '),
                              style: bodyStyle(context, size: 15, weight: FontWeight.w600),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Eintrag löschen',
                            onPressed: () => state.removeBody(e),
                            icon: Icon(Icons.delete_outline, color: c.text3),
                          ),
                        ],
                      ),
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
