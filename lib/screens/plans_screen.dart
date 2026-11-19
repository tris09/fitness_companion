import 'package:flutter/material.dart';

import '../catalog.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../training_memory.dart';
import 'chat_screen.dart';
import 'planner_screen.dart';
import 'timer_screen.dart';

class PlansScreen extends StatelessWidget {
  const PlansScreen({super.key});

  Future<void> _confirmDelete(BuildContext context, Plan plan) async {
    final AppColors c = AppColors.of(context);
    final AppState state = AppScope.of(context);
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext d) {
        return AlertDialog(
          backgroundColor: c.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadius)),
          title: Text('Plan löschen?', style: bodyStyle(d, size: 18, weight: FontWeight.w600)),
          content: Text('„${plan.name}“ wird endgültig gelöscht.', style: bodyStyle(d, color: c.text2)),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(d).pop(false),
              child: Text('Abbrechen', style: bodyStyle(d, weight: FontWeight.w600)),
            ),
            TextButton(
              onPressed: () => Navigator.of(d).pop(true),
              child: Text('Löschen', style: bodyStyle(d, weight: FontWeight.w600, color: c.accentText)),
            ),
          ],
        );
      },
    );
    if (ok == true) {
      state.deletePlan(plan.id);
    }
  }

  /// Puts the plan on a day in the calendar.
  Future<void> _planDay(BuildContext context, Plan plan) async {
    final AppState state = AppScope.of(context);
    final DateTime now = DateTime.now();
    final DateTime? d = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 180)),
      helpText: 'Tag für „${plan.name}“',
    );
    if (d != null) {
      state.addUnit(d, plan.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${plan.name} am ${d.day}.${d.month}. eingeplant.')));
      }
    }
  }

  void _pickTemplate(BuildContext context) {
    final AppColors c = AppColors.of(context);
    final AppState state = AppScope.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text('VORLAGE WÄHLEN', style: heading(sheetContext, 30)),
                const SizedBox(height: 16),
                for (final String style in templateStyles)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: SecondaryButton(
                      label: style,
                      onPressed: () {
                        state.addPlans(templatePlans(style, state.newId));
                        Navigator.of(sheetContext).pop();
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    final AppState state = AppScope.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const PageHeader(kicker: 'Deine Trainingspläne', title: 'Pläne', band: true),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            children: <Widget>[
              // Only templates. Plans made for one calendar day live in the calendar.
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  'Vorlagen für jeden Tag. Pläne, die du im Kalender für einen bestimmten Tag erstellst, findest du nur dort.',
                  style: bodyStyle(context, size: 13, color: c.text2),
                ),
              ),
              if (state.templates.isEmpty)
                Text('Noch keine Vorlage vorhanden.', style: bodyStyle(context, color: c.text2)),
              for (final Plan plan in state.templates)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(child: Text(plan.name.toUpperCase(), style: heading(context, 28))),
                            IconButton(
                              tooltip: 'Für einen Tag planen',
                              onPressed: () => _planDay(context, plan),
                              icon: Icon(Icons.event_outlined, color: c.text2),
                            ),
                            IconButton(
                              tooltip: 'Plan löschen',
                              onPressed: () => _confirmDelete(context, plan),
                              icon: Icon(Icons.delete_outline, color: c.text2),
                            ),
                          ],
                        ),
                        Text(
                          '${plan.items.length} Übungen · ca. ${plan.estimatedMinutes} min',
                          style: bodyStyle(context, size: 14, color: c.text2),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: PrimaryButton(
                                label: 'Starten',
                                height: 48,
                                onPressed: plan.items.isEmpty
                                    ? null
                                    : () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute<void>(builder: (BuildContext _) => TimerScreen(plan: plan)),
                                        );
                                      },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: SecondaryButton(
                                label: 'Bearbeiten',
                                height: 48,
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(builder: (BuildContext _) => PlannerScreen(plan: plan)),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              _Recommended(state: state),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: SecondaryButton(label: 'Vorlage nach Trainingsstil', onPressed: () => _pickTemplate(context)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: PrimaryButton(
            label: 'Neuer Plan',
            icon: Icons.add,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (BuildContext _) => const PlannerScreen()),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Suggestions from the progress: muscle groups that came short, and weights that can go up.
class _Recommended extends StatelessWidget {
  final AppState state;

  const _Recommended({required this.state});

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    final List<String> due = state.dueMuscles.take(2).toList();
    final List<MapEntry<String, double>> ups = <MapEntry<String, double>>[];
    state.weights.forEach((String id, List<WeightEntry> l) {
      final double? next = state.suggestedWeight(id);
      if (l.isNotEmpty && next != null && next > l.last.kg) {
        ups.add(MapEntry<String, double>(id, next));
      }
    });
    if (due.isEmpty && ups.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SectionLabel('Empfohlen für dich'),
        const SizedBox(height: 8),
        for (final String g in due)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: c.surface,
              border: Border(
                left: BorderSide(color: c.accent, width: 4),
                top: BorderSide(color: c.border),
                right: BorderSide(color: c.border),
                bottom: BorderSide(color: c.border),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                SectionLabel('$g · zuletzt ${agoText(state.muscleLast[g])}'),
                const SizedBox(height: 4),
                Text('SCHWERPUNKT ${g.toUpperCase()}', style: heading(context, 24)),
                const SizedBox(height: 10),
                if (state.features.coach)
                  SecondaryButton(
                    label: 'Coach erstellt Plan',
                    height: 44,
                    fontSize: 16,
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (BuildContext _) => ChatScreen(
                          initialPrompt: 'Erstelle mir einen Plan mit Schwerpunkt $g. Nutze meine letzten Gewichte.',
                        ),
                      ),
                    ),
                  )
                else
                  Text('Tipp: Nimm eine Übung für $g in deinen nächsten Plan auf.', style: bodyStyle(context, size: 13, color: c.text2)),
              ],
            ),
          ),
        if (ups.isNotEmpty)
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SectionLabel('Gewicht steigern'),
                const SizedBox(height: 8),
                for (final MapEntry<String, double> e in ups.take(4))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: <Widget>[
                        Expanded(child: Text(exerciseById(e.key).name, style: bodyStyle(context, size: 15, weight: FontWeight.w600))),
                        Text('nächstes Mal ${formatKg(e.value)}', style: bodyStyle(context, size: 14, color: c.text2)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 12),
      ],
    );
  }
}
