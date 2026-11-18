import 'package:flutter/material.dart';

import '../catalog.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../training_memory.dart';
import '../widgets/common.dart';

/// Weight history per exercise as a line chart, with the personal record.
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    final AppState state = AppScope.of(context);
    final List<String> ids = state.weights.keys.where((String id) => state.weights[id]!.isNotEmpty).toList()
      ..sort((String a, String b) => exerciseById(a).name.compareTo(exerciseById(b).name));
    final String? id = ids.contains(_selected) ? _selected : (ids.isEmpty ? null : ids.first);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const PageHeader(kicker: 'Deine Entwicklung', title: 'Fortschritt', showBack: true),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  AppCard(
                    child: Row(
                      children: <Widget>[
                        Expanded(child: _stat(context, 'Diese Woche', '${state.workoutsThisWeek} / ${state.weekGoal}')),
                        Expanded(child: _stat(context, 'Serie', '${state.streak} ${state.streak == 1 ? 'Woche' : 'Wochen'}')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (id == null)
                    Text(
                      'Noch keine Gewichte eingetragen. Nach dem Training fragt dich die App danach.',
                      style: bodyStyle(context, size: 15, color: c.text2),
                    )
                  else ...<Widget>[
                    const SectionLabel('Übung'),
                    const SizedBox(height: 8),
                    EvenGrid(
                      columns: 2,
                      children: <Widget>[
                        for (final String e in ids)
                          InkWell(
                            onTap: () => setState(() => _selected = e),
                            child: ChipBox(text: exerciseById(e).name, selected: e == id, height: 44),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _detail(context, state, id),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SectionLabel(label),
        const SizedBox(height: 4),
        Text(value.toUpperCase(), style: heading(context, 30)),
      ],
    );
  }

  Widget _detail(BuildContext context, AppState state, String id) {
    final AppColors c = AppColors.of(context);
    final List<WeightEntry> list = state.weights[id]!;
    final double? record = state.records[id];
    final double? next = suggestWeight(list);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(exerciseById(id).name.toUpperCase(), style: heading(context, 26)),
          const SizedBox(height: 4),
          Text(
            '${record == null ? '' : 'Rekord ${formatKg(record)}'}${next == null ? '' : ' · Nächstes Mal ${formatKg(next)}'}',
            style: bodyStyle(context, size: 14, weight: FontWeight.w600, color: c.accentText),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 180,
            child: CustomPaint(
              painter: _LineChart(
                values: list.map((WeightEntry e) => e.kg).toList(),
                line: c.accentText,
                grid: c.border,
                label: c.text2,
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (final WeightEntry e in list.reversed.take(6))
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: <Widget>[
                  SizedBox(width: 92, child: Text('${e.date.day}.${e.date.month}.', style: bodyStyle(context, size: 14, color: c.text2))),
                  Expanded(child: Text('${formatKg(e.kg)} × ${e.reps}', style: bodyStyle(context, size: 14, weight: FontWeight.w600))),
                  Text(e.feel, style: bodyStyle(context, size: 13, color: c.text2)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Small line chart without extra packages. Oldest value on the left.
class _LineChart extends CustomPainter {
  final List<double> values;
  final Color line;
  final Color grid;
  final Color label;

  _LineChart({required this.values, required this.line, required this.grid, required this.label});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) {
      return;
    }
    double lo = values.reduce((double a, double b) => a < b ? a : b);
    double hi = values.reduce((double a, double b) => a > b ? a : b);
    if (hi - lo < 5) {
      lo -= 2.5;
      hi += 2.5;
    }
    const double left = 44;
    final double w = size.width - left - 8;
    final double h = size.height - 12;
    final Paint gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (int i = 0; i <= 2; i++) {
      final double y = 6 + h * i / 2;
      canvas.drawLine(Offset(left, y), Offset(size.width, y), gridPaint);
      final double v = hi - (hi - lo) * i / 2;
      final TextPainter tp = TextPainter(
        text: TextSpan(text: formatKg(v), style: TextStyle(color: label, fontSize: 11)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, y - tp.height / 2));
    }
    Offset point(int i) {
      final double x = left + (values.length == 1 ? w / 2 : w * i / (values.length - 1));
      final double y = 6 + h * (1 - (values[i] - lo) / (hi - lo));
      return Offset(x, y);
    }

    final Paint linePaint = Paint()
      ..color = line
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final Path path = Path()..moveTo(point(0).dx, point(0).dy);
    for (int i = 1; i < values.length; i++) {
      path.lineTo(point(i).dx, point(i).dy);
    }
    canvas.drawPath(path, linePaint);
    final Paint dot = Paint()..color = line;
    for (int i = 0; i < values.length; i++) {
      canvas.drawRect(Rect.fromCenter(center: point(i), width: 8, height: 8), dot);
    }
  }

  @override
  bool shouldRepaint(_LineChart old) => old.values != values || old.line != line;
}
