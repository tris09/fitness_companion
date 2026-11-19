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

  /// Upcoming day plans first (soonest on top), then past ones (newest on top).
  List<Plan> _dayPlansSorted(AppState state) {
    final DateTime today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final List<Plan> list = state.plans.where((Plan p) => !p.isTemplate).toList();
    DateTime d(Plan p) => AppState.dayFromKey(p.day!) ?? today;
    final List<Plan> next = list.where((Plan p) => !d(p).isBefore(today)).toList()..sort((Plan a, Plan b) => d(a).compareTo(d(b)));
    final List<Plan> past = list.where((Plan p) => d(p).isBefore(today)).toList()..sort((Plan a, Plan b) => d(b).compareTo(d(a)));
    return <Plan>[...next, ...past];
  }

  static String _weekdays(List<int> wd) => wd.map((int d) => weekdayShort[d - 1]).join(', ');

  Widget _actions(BuildContext context, Plan plan) {
    return Row(
      children: <Widget>[
        Expanded(
          child: PrimaryButton(
            label: 'Starten',
            height: 48,
            onPressed: plan.items.isEmpty
                ? null
                : () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (BuildContext _) => TimerScreen(plan: plan))),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SecondaryButton(
            label: 'Bearbeiten',
            height: 48,
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (BuildContext _) => PlannerScreen(plan: plan))),
          ),
        ),
      ],
    );
  }

  Widget _templateCard(BuildContext context, AppState state, Plan plan) {
    final AppColors c = AppColors.of(context);
    final WeekRule? rule = state.ruleOf(plan.id);
    return Padding(
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
            Text('${plan.items.length} Übungen · ca. ${plan.estimatedMinutes} min', style: bodyStyle(context, size: 14, color: c.text2)),
            const SizedBox(height: 10),
            // Fixed weekdays: the template appears in the calendar on these days.
            InkWell(
              onTap: () => _pickWeekdays(context, state, plan),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: rule == null ? c.control : c.lime,
                  border: Border.all(color: rule == null ? c.outline : (c.accentEdge ?? c.lime), width: rule == null ? c.borderWidth : 1.5),
                  borderRadius: BorderRadius.circular(kRadius),
                ),
                child: Row(
                  children: <Widget>[
                    Icon(Icons.repeat, size: 20, color: rule == null ? c.text : c.onLime),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        rule == null ? 'Wochentage zuweisen' : 'Jeden ${_weekdays(rule.weekdays)} im Kalender',
                        style: bodyStyle(context, size: 14, weight: FontWeight.w700, color: rule == null ? c.text : c.onLime),
                      ),
                    ),
                    Icon(Icons.chevron_right, size: 20, color: rule == null ? c.text3 : c.onLime),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            _actions(context, plan),
          ],
        ),
      ),
    );
  }

  Widget _dayPlanCard(BuildContext context, AppState state, Plan plan) {
    final AppColors c = AppColors.of(context);
    final DateTime? day = AppState.dayFromKey(plan.day!);
    final bool done = state.isDayPlanDone(plan);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Text(
                  day == null ? '' : '${weekdayShort[day.weekday - 1]} ${day.day}.${day.month}.${day.year}',
                  style: bodyStyle(context, size: 14, weight: FontWeight.w700),
                ),
                const Spacer(),
                // Two states: planned or done.
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: done ? c.lime : c.control,
                    border: Border.all(color: done ? (c.accentEdge ?? c.lime) : c.outline),
                    borderRadius: BorderRadius.circular(kRadius),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(done ? Icons.check : Icons.schedule, size: 16, color: done ? c.onLime : c.text),
                      const SizedBox(width: 4),
                      Text(done ? 'Absolviert' : 'Geplant', style: bodyStyle(context, size: 12, weight: FontWeight.w700, color: done ? c.onLime : c.text)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: <Widget>[
                Expanded(child: Text(plan.name.toUpperCase(), style: heading(context, 26))),
                IconButton(
                  tooltip: 'Als Vorlage speichern',
                  onPressed: () {
                    final Plan t = state.saveAsTemplate(plan);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('„${t.name}“ ist jetzt eine Vorlage.')));
                  },
                  icon: Icon(Icons.bookmark_add_outlined, color: c.text2),
                ),
                IconButton(
                  tooltip: 'Tagesplan löschen',
                  onPressed: () => _confirmDelete(context, plan),
                  icon: Icon(Icons.delete_outline, color: c.text2),
                ),
              ],
            ),
            Text('${plan.items.length} Übungen · ca. ${plan.estimatedMinutes} min', style: bodyStyle(context, size: 14, color: c.text2)),
            const SizedBox(height: 12),
            _actions(context, plan),
          ],
        ),
      ),
    );
  }

  /// Weekday picker for a template. Saving creates or replaces the weekly rule.
  void _pickWeekdays(BuildContext context, AppState state, Plan plan) {
    final Set<int> picked = <int>{...?state.ruleOf(plan.id)?.weekdays};
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (BuildContext sheet) => StatefulBuilder(
        builder: (BuildContext ctx, StateSetter set) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text('FESTE TAGE', style: heading(ctx, 28)),
                const SizedBox(height: 4),
                Text('„${plan.name}“ steht ab heute an diesen Tagen im Kalender. Einzelne Tage kannst du dort wieder entfernen.',
                    style: bodyStyle(ctx, size: 14, color: AppColors.of(ctx).text2)),
                const SizedBox(height: 14),
                EvenGrid(
                  columns: 7,
                  children: <Widget>[
                    for (int d = 1; d <= 7; d++)
                      InkWell(
                        onTap: () => set(() => picked.contains(d) ? picked.remove(d) : picked.add(d)),
                        child: ChipBox(text: weekdayShort[d - 1], selected: picked.contains(d), height: 48, showCheck: false),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                PrimaryButton(
                  label: picked.isEmpty ? 'Keine festen Tage' : 'Speichern',
                  onPressed: () {
                    state.setWeekRule(plan.id, picked.toList());
                    Navigator.of(sheet).pop();
                  },
                ),
              ],
            ),
          );
        },
      ),
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
              // All plans: templates (usable on any day, optionally on fixed weekdays)
              // and day plans (one date, planned or done).
              _Section(
                title: 'Vorlagen',
                count: state.templates.length,
                note: 'Für jeden Tag nutzbar. Mit „Wochentage“ legst du feste Trainingstage fest.',
                initiallyOpen: true,
                children: <Widget>[
                  if (state.templates.isEmpty) Text('Noch keine Vorlage vorhanden.', style: bodyStyle(context, color: c.text2)),
                  for (final Plan plan in state.templates) _templateCard(context, state, plan),
                ],
              ),
              const SizedBox(height: 10),
              _Section(
                title: 'Tagespläne',
                count: state.plans.where((Plan p) => !p.isTemplate).length,
                note: 'Für ein bestimmtes Datum erstellt. Sie stehen im Kalender und bleiben 6 Monate gespeichert.',
                initiallyOpen: false,
                children: <Widget>[
                  if (state.plans.every((Plan p) => p.isTemplate))
                    Text('Noch kein Tagesplan. Erstelle einen über den Kalender auf Home oder lass den Coach Tage planen.',
                        style: bodyStyle(context, color: c.text2)),
                  for (final Plan plan in _dayPlansSorted(state)) _dayPlanCard(context, state, plan),
                ],
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

/// Fold-out section with title, count and a short note.
class _Section extends StatefulWidget {
  final String title;
  final int count;
  final String note;
  final bool initiallyOpen;
  final List<Widget> children;

  const _Section({required this.title, required this.count, required this.note, required this.initiallyOpen, required this.children});

  @override
  State<_Section> createState() => _SectionState();
}

class _SectionState extends State<_Section> {
  late bool _open = widget.initiallyOpen;

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Semantics(
          button: true,
          expanded: _open,
          child: InkWell(
            onTap: () => setState(() => _open = !_open),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.border))),
              child: Row(
                children: <Widget>[
                  Expanded(child: Text(widget.title.toUpperCase(), style: heading(context, 24))),
                  Text('${widget.count}', style: bodyStyle(context, size: 14, weight: FontWeight.w700, color: c.text2)),
                  const SizedBox(width: 6),
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: kFast,
                    child: Icon(Icons.expand_more, color: c.text),
                  ),
                ],
              ),
            ),
          ),
        ),
        Reveal(
          show: _open,
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(widget.note, style: bodyStyle(context, size: 13, color: c.text2)),
                ),
                ...widget.children,
              ],
            ),
          ),
        ),
      ],
    );
  }
}
