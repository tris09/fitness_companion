import 'package:flutter/material.dart';

import '../catalog.dart';
import '../models.dart';
import '../screens/chat_screen.dart';
import '../screens/planner_screen.dart';
import '../screens/timer_screen.dart';
import '../services/notifications.dart';
import '../state.dart';
import '../theme.dart';
import 'common.dart';

const List<String> kWeekdayShort = <String>['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
const List<String> kWeekdayLong = <String>['Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag', 'Samstag', 'Sonntag'];
const List<String> kMonths = <String>[
  'Januar', 'Februar', 'März', 'April', 'Mai', 'Juni',
  'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember',
];

DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);
DateTime mondayOf(DateTime d) => dayOnly(d).subtract(Duration(days: d.weekday - 1));
bool sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

/// ISO week number.
int isoWeek(DateTime d) {
  final DateTime thursday = dayOnly(d).add(Duration(days: 4 - d.weekday));
  final DateTime firstThursday = DateTime(thursday.year, 1, 4);
  final DateTime week1 = mondayOf(firstThursday);
  return 1 + thursday.difference(week1).inDays ~/ 7;
}

/// 'Mittwoch, 18. November'
String longDate(DateTime d) => '${kWeekdayLong[d.weekday - 1]}, ${d.day}. ${kMonths[d.month - 1]}';

/// Week strip with one selected day and the plan of that day below.
/// Tapping a day slides the plan card sideways to that day.
class DayPlanner extends StatefulWidget {
  const DayPlanner({super.key});

  @override
  State<DayPlanner> createState() => _DayPlannerState();
}

class _DayPlannerState extends State<DayPlanner> {
  late DateTime _weekStart;
  late int _selected;
  late PageController _pages;

  @override
  void initState() {
    super.initState();
    final DateTime now = DateTime.now();
    _weekStart = mondayOf(now);
    _selected = now.weekday - 1;
    _pages = PageController(initialPage: _selected);
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _pick(int i) {
    if (i == _selected) {
      return;
    }
    setState(() {
      _selected = i;
    });
    _pages.animateToPage(i, duration: const Duration(milliseconds: 340), curve: kEase);
  }

  /// The calendar covers 6 months back to 6 months ahead (see DataLimits).
  bool _canShift(int delta) {
    final DateTime start = _weekStart.add(Duration(days: 7 * delta));
    final DateTime end = start.add(const Duration(days: 6));
    return !end.isBefore(DataLimits.firstDay) && !start.isAfter(DataLimits.lastDay);
  }

  void _shiftWeek(int delta) {
    if (!_canShift(delta)) {
      return;
    }
    setState(() {
      _weekStart = _weekStart.add(Duration(days: 7 * delta));
      _selected = delta > 0 ? 0 : 6;
    });
    _pages.jumpToPage(_selected);
  }

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    final AppState state = AppScope.of(context);
    final DateTime today = dayOnly(DateTime.now());
    final List<DateTime> days = <DateTime>[for (int i = 0; i < 7; i++) _weekStart.add(Duration(days: i))];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            IconButton(
              tooltip: 'Vorherige Woche',
              onPressed: _canShift(-1) ? () => _shiftWeek(-1) : null,
              icon: Icon(Icons.chevron_left, color: c.text2),
            ),
            Expanded(
              child: Text(
                'KW ${isoWeek(_weekStart)} · ${kMonths[days[_selected].month - 1]}'.toUpperCase(),
                textAlign: TextAlign.center,
                style: heading(context, 22),
              ),
            ),
            IconButton(
              tooltip: 'Nächste Woche',
              onPressed: _canShift(1) ? () => _shiftWeek(1) : null,
              icon: Icon(Icons.chevron_right, color: c.text2),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: <Widget>[
            for (int i = 0; i < 7; i++)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i == 6 ? 0 : 5),
                  child: _DayBox(
                    label: kWeekdayShort[i],
                    day: days[i],
                    today: sameDay(days[i], today),
                    planned: !days[i].isBefore(today) && state.unitsOn(days[i]).isNotEmpty,
                    selected: i == _selected,
                    onTap: () => _pick(i),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        _Legend(),
        const SizedBox(height: 12),
        SizedBox(
          height: 330,
          child: PageView.builder(
            controller: _pages,
            itemCount: 7,
            onPageChanged: (int i) => setState(() => _selected = i),
            itemBuilder: (BuildContext _, int i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: DayCard(day: days[i]),
            ),
          ),
        ),
      ],
    );
  }
}

class _DayBox extends StatelessWidget {
  final String label;
  final DateTime day;
  final bool today;
  final bool planned;
  final bool selected;
  final VoidCallback onTap;

  const _DayBox({
    required this.label,
    required this.day,
    required this.today,
    required this.planned,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    final Color ink = AppColors.of(context).onLime;
    return Semantics(
      button: true,
      selected: selected,
      label: '$label ${day.day}.${today ? ', heute' : ''}${planned ? ', Training geplant' : ''}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          children: <Widget>[
            Text(label.toUpperCase(), style: labelStyle(context)),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: kFast,
              curve: kEase,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                border: Border.all(color: selected ? c.text : Colors.transparent, width: 2),
                borderRadius: BorderRadius.circular(kRadius + 2),
              ),
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: today ? c.lime : c.surface,
                  border: Border.all(color: today ? c.lime : c.border, width: c.borderWidth),
                  borderRadius: BorderRadius.circular(kRadius),
                ),
                child: Stack(
                  children: <Widget>[
                    Center(
                      child: Text(
                        '${day.day}',
                        style: heading(context, 19, color: today ? ink : (planned ? c.text : c.text3)),
                      ),
                    ),
                    if (planned)
                      Positioned(
                        left: 9,
                        right: 9,
                        bottom: 5,
                        child: Container(height: 3, color: today ? ink : c.strike),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    Widget item(Widget box, String text) => Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[box, const SizedBox(width: 6), Text(text, style: bodyStyle(context, size: 12, color: c.text2))],
        );
    return Wrap(
      spacing: 16,
      children: <Widget>[
        item(Container(width: 12, height: 12, color: c.lime), 'Heute'),
        item(
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(border: Border.all(color: c.border)),
            alignment: Alignment.bottomCenter,
            child: Container(height: 3, color: c.strike),
          ),
          'Training',
        ),
        item(Container(width: 12, height: 12, decoration: BoxDecoration(border: Border.all(color: c.border))), 'Frei'),
      ],
    );
  }
}

/// Plan of one day. Lime when something is planned, plain when the day is free.
class DayCard extends StatelessWidget {
  final DateTime day;

  const DayCard({super.key, required this.day});

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    final AppState state = AppScope.of(context);
    final List<ScheduledUnit> units = state.unitsOn(day);
    final DateTime today = dayOnly(DateTime.now());
    final String caption =
        '${kWeekdayLong[day.weekday - 1]}${sameDay(day, today) ? ' · Heute' : ''} · ${day.day}. ${kMonths[day.month - 1].substring(0, 3)}'
            .toUpperCase();
    if (units.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.surface,
          border: Border.all(color: c.border, width: c.borderWidth),
          borderRadius: BorderRadius.circular(kRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(caption, style: labelStyle(context)),
            const SizedBox(height: 8),
            Text('KEIN TRAINING', style: heading(context, 34)),
            const SizedBox(height: 6),
            Text(state.features.coach ? 'Freier Tag. Leg einen Plan an oder lass den Coach planen.' : 'Freier Tag. Leg einen Plan an oder genieß die Pause.', style: bodyStyle(context, size: 14, color: c.text2)),
            const Spacer(),
            Row(
              children: <Widget>[
                Expanded(
                  child: PrimaryButton(label: 'Plan anlegen', height: 46, fontSize: 16, onPressed: () => showDaySheet(context, day)),
                ),
                if (state.features.coach) ...<Widget>[
                  const SizedBox(width: 8),
                  Expanded(
                    child: SecondaryButton(
                      label: 'Coach plant',
                      height: 46,
                      fontSize: 16,
                      onPressed: () => _askCoach(context, day),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      );
    }

    final Color ink = AppColors.of(context).onLime;
    final Plan main = state.planById(units.first.planId)!;
    final List<String> names = main.items.take(3).map((PlanItem it) => exerciseById(it.exerciseId).name).toList();
    final String meta = <String>[
      '${main.items.length} Übungen',
      'ca. ${main.estimatedMinutes} min',
      if (units.first.hasTime) units.first.timeText,
      // Day plans exist only on this day; templates are also under "Pläne".
      if (!main.isTemplate) 'nur dieser Tag',
      if (state.isDone(day, main.id)) '✓ absolviert',
    ].join(' · ');
    final bool contrastLight = c.highContrast && !c.isDark;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 16),
      decoration: BoxDecoration(
        color: c.lime,
        border: contrastLight ? Border.all(color: ink, width: 2) : null,
        borderRadius: BorderRadius.circular(kRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: Text(caption, style: labelStyle(context, color: ink))),
              _UnitMenu(day: day, units: units),
            ],
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(main.name.toUpperCase(), style: heading(context, 40, color: ink)),
          ),
          const SizedBox(height: 4),
          Text(meta, style: bodyStyle(context, size: 13, weight: FontWeight.w500, color: ink)),
          const SizedBox(height: 8),
          for (int i = 0; i < names.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text('${i + 1}  ${names[i]}', style: bodyStyle(context, size: 14, weight: FontWeight.w600, color: ink)),
            ),
          for (final ScheduledUnit u in units.skip(1))
            Text(
              '+ ${state.planById(u.planId)!.name}${u.hasTime ? ' · ${u.timeText}' : ''}',
              style: bodyStyle(context, size: 13, weight: FontWeight.w600, color: ink),
            ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: FilledButton(
                      onPressed: main.items.isEmpty
                          ? null
                          : () => Navigator.of(context).push(
                                MaterialPageRoute<void>(builder: (BuildContext _) => TimerScreen(plan: main)),
                              ),
                      style: FilledButton.styleFrom(
                        // Inverse of the accent fill: dark button on light accents, light on dark ones.
                        backgroundColor: ink,
                        foregroundColor: c.lime,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadius)),
                      ),
                      child: Text('STARTEN', style: heading(context, 18, color: c.lime)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (BuildContext _) => PlannerScreen(plan: main)),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ink,
                        side: BorderSide(color: ink, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadius)),
                      ),
                      child: Text('BEARBEITEN', style: heading(context, 18, color: ink)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Small menu on the plan card: add another unit or remove one.
class _UnitMenu extends StatelessWidget {
  final DateTime day;
  final List<ScheduledUnit> units;

  const _UnitMenu({required this.day, required this.units});

  @override
  Widget build(BuildContext context) {
    final AppState state = AppScope.of(context);
    return PopupMenuButton<String>(
      tooltip: 'Einheiten',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 220),
      icon: Icon(Icons.more_horiz, color: AppColors.of(context).onLime),
      onSelected: (String v) {
        if (v == '+') {
          showDaySheet(context, day);
        } else {
          state.removeUnit(v);
        }
      },
      itemBuilder: (BuildContext _) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(value: '+', child: Text('Weitere Einheit hinzufügen')),
        for (final ScheduledUnit u in units)
          PopupMenuItem<String>(
            value: u.id,
            child: Text('Entfernen: ${state.planById(u.planId)?.name ?? 'Plan'}${u.hasTime ? ' (${u.timeText})' : ''}'),
          ),
      ],
    );
  }
}

void _askCoach(BuildContext context, DateTime day) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (BuildContext _) => ChatScreen(
        initialPrompt: 'Plane mir ein Training für ${longDate(day)} '
            '(${day.year}-${two(day.month)}-${two(day.day)}). '
            'Berücksichtige meine letzten Trainings, meine Vorlieben und meine Körperdaten.',
      ),
    ),
  );
}

/// Bottom sheet to put a plan on a day, with an optional time.
Future<void> showDaySheet(BuildContext context, DateTime day) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.of(context).bg,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    builder: (BuildContext _) => _DaySheet(day: day),
  );
}

class _DaySheet extends StatefulWidget {
  final DateTime day;

  const _DaySheet({required this.day});

  @override
  State<_DaySheet> createState() => _DaySheetState();
}

class _DaySheetState extends State<_DaySheet> {
  String? _planId;
  bool _withTime = false;
  TimeOfDay _time = const TimeOfDay(hour: 18, minute: 0);

  Future<void> _pickTime() async {
    final TimeOfDay? t = await showTimePicker(
      context: context,
      initialTime: _time,
      builder: (BuildContext ctx, Widget? child) =>
          MediaQuery(data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true), child: child ?? const SizedBox()),
    );
    if (t != null) {
      setState(() {
        _time = t;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    final AppState state = AppScope.of(context);
    final String time = '${two(_time.hour)}:${two(_time.minute)}';
    final int remindH = (_time.hour * 60 + _time.minute - 30) ~/ 60;
    final int remindM = (_time.hour * 60 + _time.minute - 30) % 60;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SectionLabel(longDate(widget.day)),
              const SizedBox(height: 6),
              Text('TAG PLANEN', style: heading(context, 32)),
              const SizedBox(height: 14),
              const SectionLabel('Vorlage verwenden'),
              const SizedBox(height: 6),
              if (state.templates.isEmpty)
                Text('Noch keine Vorlage vorhanden.', style: bodyStyle(context, color: c.text2)),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: <Widget>[
                    for (final Plan p in state.templates)
                      InkWell(
                        onTap: () => setState(() => _planId = p.id),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(border: Border(top: BorderSide(color: c.border))),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(p.name, style: bodyStyle(context, size: 16, weight: FontWeight.w700)),
                                    Text('${p.items.length} Übungen · ca. ${p.estimatedMinutes} min',
                                        style: bodyStyle(context, size: 13, color: c.text3)),
                                  ],
                                ),
                              ),
                              Icon(
                                _planId == p.id ? Icons.check_box : Icons.check_box_outline_blank,
                                color: _planId == p.id ? c.text : c.border,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // A plan made here belongs to this day only: it is not listed under
              // "Pläne" and is removed together with its calendar entry.
              TextButton(
                onPressed: () {
                  final NavigatorState nav = Navigator.of(context);
                  final int? minute = _withTime ? _time.hour * 60 + _time.minute : null;
                  nav.pop();
                  nav.push(MaterialPageRoute<void>(
                    builder: (BuildContext _) => PlannerScreen(forDay: widget.day, minute: minute),
                  ));
                },
                child: Text('+ Plan nur für diesen Tag erstellen', style: bodyStyle(context, size: 14, weight: FontWeight.w700)),
              ),
              const SizedBox(height: 6),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text('Uhrzeit angeben', style: bodyStyle(context, size: 15, weight: FontWeight.w700)),
                              Text('Optional. Erinnerung 30 Minuten vorher per Push.',
                                  style: bodyStyle(context, size: 12, color: c.text3)),
                            ],
                          ),
                        ),
                        Switch(
                          value: _withTime,
                          onChanged: (bool v) => setState(() => _withTime = v),
                        ),
                      ],
                    ),
                    Reveal(
                      show: _withTime,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                'Erinnerung um ${two(remindH < 0 ? 0 : remindH)}:${two(remindM < 0 ? 0 : remindM)}',
                                style: bodyStyle(context, size: 13, color: c.text2),
                              ),
                            ),
                            SecondaryButton(label: time, expand: false, height: 44, fontSize: 20, onPressed: _pickTime),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              PrimaryButton(
                label: 'Zum Tag hinzufügen',
                onPressed: _planId == null
                    ? null
                    : () async {
                        final NavigatorState nav = Navigator.of(context);
                        state.addUnit(widget.day, _planId!, minute: _withTime ? _time.hour * 60 + _time.minute : null);
                        if (_withTime && state.pushEnabled) {
                          await NotificationService.instance.requestPermission();
                        }
                        nav.pop();
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
