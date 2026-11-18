import 'package:flutter/material.dart';

import '../models.dart';
import '../services/notifications.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/wheel_picker.dart';

/// The stretch plan: random stretches, spread evenly over the day and sent as
/// push notifications. Runs on fixed weekdays, only today, or both.
class StretchScreen extends StatefulWidget {
  const StretchScreen({super.key});

  @override
  State<StretchScreen> createState() => _StretchScreenState();
}

class _StretchScreenState extends State<StretchScreen> {
  /// Index of the open stretch in today's plan. Null = the next one that is not done.
  int? _open;

  Future<bool> _askPermission() async {
    final bool allowed = await NotificationService.instance.requestPermission();
    if (!allowed && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Benachrichtigungen sind nicht erlaubt. Bitte in den Handy-Einstellungen freigeben.')),
      );
    }
    return allowed;
  }

  Future<void> _setToday(AppState state, bool on) async {
    if (on && !await _askPermission()) {
      return;
    }
    state.setToday(on);
  }

  Future<void> _setWeekly(AppState state, bool on) async {
    if (on && !await _askPermission()) {
      return;
    }
    state.updateStretch(state.stretch.copy()..enabled = on);
  }

  Future<void> _pickHour(AppState state, bool start) async {
    final StretchSettings s = state.stretch;
    final int? v = await showWheelPicker(
      context,
      title: start ? 'Erste Übung ab' : 'Letzte Übung bis',
      values: numberRange(5, 23),
      initial: start ? s.startHour : s.endHour,
      label: (int h) => '${two(h)}:00',
    );
    if (v == null) {
      return;
    }
    final StretchSettings n = s.copy();
    if (start) {
      n.startHour = v;
      if (n.endHour <= v) {
        n.endHour = (v + 1).clamp(6, 24);
      }
    } else {
      n.endHour = v;
      if (n.startHour >= v) {
        n.startHour = (v - 1).clamp(0, 22);
      }
    }
    state.updateStretch(n);
  }

  Widget _switchRow(String title, String sub, bool value, ValueChanged<bool> onChanged) {
    final AppColors c = AppColors.of(context);
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: bodyStyle(context, size: 16, weight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(sub, style: bodyStyle(context, size: 13, color: c.text2)),
            ],
          ),
        ),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }

  Widget _weekdays(AppState state) {
    final AppColors c = AppColors.of(context);
    final StretchSettings s = state.stretch;
    return Row(
      children: <Widget>[
        for (int d = 1; d <= 7; d++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: d == 7 ? 0 : 6),
              child: InkWell(
                onTap: () {
                  final StretchSettings n = s.copy();
                  if (n.weekdays.contains(d)) {
                    n.weekdays.remove(d);
                  } else {
                    n.weekdays.add(d);
                  }
                  state.updateStretch(n);
                },
                child: AnimatedContainer(
                  duration: kFast,
                  curve: kEase,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: s.weekdays.contains(d) ? c.accent : Colors.transparent,
                    border: Border.all(color: s.weekdays.contains(d) ? c.accent : c.border),
                    borderRadius: BorderRadius.circular(kRadius),
                  ),
                  child: Text(
                    weekdayShort[d - 1],
                    style: bodyStyle(context, size: 13, weight: FontWeight.w600, color: s.weekdays.contains(d) ? c.onAccent : c.text2),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// One stretch with its steps and the done button.
  Widget _detail(AppState state, Stretch st, bool done) {
    final AppColors c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (int i = 0; i < st.steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('${i + 1}. ${st.steps[i]}', style: bodyStyle(context, size: 14, color: c.text2)),
            ),
          const SizedBox(height: 6),
          PrimaryButton(
            label: done ? 'Erledigt' : 'Erledigt · ${st.seconds} s gehalten',
            height: 48,
            fontSize: 18,
            onPressed: done
                ? null
                : () {
                    state.markStretchDone(st.id);
                    setState(() => _open = null);
                  },
          ),
        ],
      ),
    );
  }

  Widget _plan(AppState state) {
    final AppColors c = AppColors.of(context);
    final List<({DateTime time, Stretch stretch})> plan = state.todayPlan;
    if (plan.isEmpty) {
      return Text(
        'Heute läuft kein Dehnplan. Aktiviere ihn oben für heute oder für feste Wochentage.',
        style: bodyStyle(context, size: 14, color: c.text2),
      );
    }
    int? open = _open;
    if (open == null) {
      final int next = plan.indexWhere((({DateTime time, Stretch stretch}) e) => !state.stretchDone.contains(e.stretch.id));
      open = next < 0 ? null : next;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (int i = 0; i < plan.length; i++) ...<Widget>[
          InkWell(
            onTap: () => setState(() => _open = open == i ? -1 : i),
            child: Container(
              constraints: const BoxConstraints(minHeight: 60),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: c.border))),
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: 56,
                    child: Text(
                      '${two(plan[i].time.hour)}:${two(plan[i].time.minute)}',
                      style: bodyStyle(context, size: 15, weight: FontWeight.w700, color: c.text2),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(plan[i].stretch.name.toUpperCase(), style: heading(context, 20)),
                        Text('${plan[i].stretch.group} · ${plan[i].stretch.seconds} s', style: bodyStyle(context, size: 13, color: c.text2)),
                      ],
                    ),
                  ),
                  if (state.stretchDone.contains(plan[i].stretch.id))
                    Icon(Icons.check_circle, color: c.accentText)
                  else
                    Icon(open == i ? Icons.expand_less : Icons.expand_more, color: c.text2),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: kFast,
            curve: kEase,
            alignment: Alignment.topCenter,
            child: open == i
                ? _detail(state, plan[i].stretch, state.stretchDone.contains(plan[i].stretch.id))
                : const SizedBox(width: double.infinity),
          ),
        ],
        const SizedBox(height: 8),
        SecondaryButton(
          label: 'Neu würfeln',
          height: 48,
          fontSize: 17,
          onPressed: () {
            state.rerollToday();
            setState(() => _open = null);
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    final AppState state = AppScope.of(context);
    final StretchSettings s = state.stretch;
    final bool today = s.todayKey == StretchSettings.keyOf(DateTime.now());
    final DateTime? next = state.nextReminder;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const PageHeader(kicker: 'Pause für den Körper', title: 'Dehnplan', showBack: true),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    'Der Dehnplan schickt dir über den Tag verteilt Push-Benachrichtigungen mit je einer Dehnübung. '
                    'Die Übungen werden zufällig gewürfelt und decken verschiedene Körperbereiche ab. '
                    'Die Zeiten verteilen sich gleichmäßig über deinen Zeitraum.',
                    style: bodyStyle(context, size: 14, color: c.text2),
                  ),
                  const SizedBox(height: 16),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        _switchRow('Heute aktivieren', 'Nur für heute, danach wieder aus', today, (bool v) => _setToday(state, v)),
                        Divider(color: c.border, height: 24),
                        _switchRow('Feste Wochentage', 'Jede Woche an diesen Tagen', s.enabled, (bool v) => _setWeekly(state, v)),
                        AnimatedSize(
                          duration: kFast,
                          curve: kEase,
                          alignment: Alignment.topCenter,
                          child: s.enabled
                              ? Padding(padding: const EdgeInsets.only(top: 12), child: _weekdays(state))
                              : const SizedBox(width: double.infinity),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          reminderLabel(s.anyActive, next),
                          style: bodyStyle(context, size: 14, weight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const SectionLabel('Zeitraum'),
                  const SizedBox(height: 8),
                  EvenGrid(
                    columns: 2,
                    children: <Widget>[
                      InkWell(onTap: () => _pickHour(state, true), child: ChipBox(text: 'Ab ${two(s.startHour)}:00', height: 48, showCheck: false)),
                      InkWell(onTap: () => _pickHour(state, false), child: ChipBox(text: 'Bis ${two(s.endHour)}:00', height: 48, showCheck: false)),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const SectionLabel('Übungen pro Tag'),
                  const SizedBox(height: 8),
                  EvenGrid(
                    columns: 5,
                    children: <Widget>[
                      for (final int n in const <int>[3, 4, 5, 6, 8])
                        InkWell(
                          onTap: () => state.updateStretch(s.copy()..perDay = n),
                          child: ChipBox(text: '$n', selected: s.perDay == n, height: 44),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const SectionLabel('Dein Plan heute'),
                  const SizedBox(height: 8),
                  _plan(state),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
