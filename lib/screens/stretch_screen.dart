import 'package:flutter/material.dart';

import '../catalog.dart';
import '../models.dart';
import '../services/notifications.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Shows one random stretch and the reminder settings.
class StretchScreen extends StatefulWidget {
  const StretchScreen({super.key});

  @override
  State<StretchScreen> createState() => _StretchScreenState();
}

class _StretchScreenState extends State<StretchScreen> {
  String? _currentId;

  StretchSettings _copy(StretchSettings s) {
    return StretchSettings(
      enabled: s.enabled,
      weekdays: Set<int>.from(s.weekdays),
      startHour: s.startHour,
      endHour: s.endHour,
      intervalMin: s.intervalMin,
    );
  }

  Future<void> _setEnabled(AppState state, bool value) async {
    final StretchSettings s = _copy(state.stretch);
    if (value) {
      final bool allowed = await NotificationService.instance.requestPermission();
      if (!allowed) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Benachrichtigungen sind nicht erlaubt. Bitte in den Handy-Einstellungen freigeben.')),
          );
        }
        return;
      }
    }
    s.enabled = value;
    state.updateStretch(s);
  }

  Widget _hourChip(String prefix, int value, void Function(int v) onSelected) {
    return PopupMenuButton<int>(
      tooltip: '$prefix ändern',
      onSelected: onSelected,
      itemBuilder: (BuildContext _) {
        return <PopupMenuEntry<int>>[
          for (int h = 5; h <= 23; h++) PopupMenuItem<int>(value: h, child: Text('${two(h)}:00')),
        ];
      },
      child: ChipBox(text: '$prefix ${two(value)}:00', height: 44),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    final AppState state = AppScope.of(context);
    final Stretch stretch = _currentId == null ? state.pickStretch() : stretchById(_currentId!);
    _currentId = stretch.id;
    final Set<String> covered = state.coveredGroups;
    final StretchSettings s = state.stretch;
    final DateTime? next = state.nextReminder;

    return ListView(
      padding: EdgeInsets.zero,
      children: <Widget>[
        const PageHeader(kicker: 'Pause für den Körper', title: 'Dehnen'),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SectionLabel('${stretch.group} · ${stretch.seconds} Sekunden'),
                    const SizedBox(height: 8),
                    Text(stretch.name.toUpperCase(), style: heading(context, 34)),
                    const SizedBox(height: 14),
                    for (int i = 0; i < stretch.steps.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          '${i + 1}. ${stretch.steps[i]}',
                          style: bodyStyle(context, size: 15, color: c.text2),
                        ),
                      ),
                    const SizedBox(height: 14),
                    PrimaryButton(
                      label: 'Erledigt',
                      height: 64,
                      fontSize: 22,
                      onPressed: () {
                        state.markStretchDone(stretch.id);
                        setState(() {
                          _currentId = state.pickStretch(notId: stretch.id).id;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    SecondaryButton(
                      label: 'Andere Übung',
                      onPressed: () {
                        setState(() {
                          _currentId = state.pickStretch(notId: stretch.id).id;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const SectionLabel('Heute angesprochen'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  for (final String g in stretchGroups)
                    ChipBox(text: covered.contains(g) ? '✓ $g' : g, selected: covered.contains(g), height: 36),
                ],
              ),
              const SizedBox(height: 24),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const SectionLabel('Erinnerungen'),
                              const SizedBox(height: 6),
                              Text(
                                reminderLabel(s.enabled, next),
                                style: bodyStyle(context, size: 15, weight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        Semantics(
                          label: 'Erinnerungen ein oder aus',
                          child: Switch(value: s.enabled, onChanged: (bool v) => _setEnabled(state, v)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const SectionLabel('Büro-Tage'),
                    const SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        for (int d = 1; d <= 7; d++)
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(right: d == 7 ? 0 : 6),
                              child: InkWell(
                                onTap: () {
                                  final StretchSettings n = _copy(s);
                                  if (n.weekdays.contains(d)) {
                                    n.weekdays.remove(d);
                                  } else {
                                    n.weekdays.add(d);
                                  }
                                  state.updateStretch(n);
                                },
                                child: Container(
                                  height: 44,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: s.weekdays.contains(d) ? c.accent : Colors.transparent,
                                    border: Border.all(color: s.weekdays.contains(d) ? c.accent : c.border),
                                    borderRadius: BorderRadius.circular(kRadius),
                                  ),
                                  child: Text(
                                    weekdayShort[d - 1],
                                    style: bodyStyle(
                                      context,
                                      size: 13,
                                      weight: FontWeight.w600,
                                      color: s.weekdays.contains(d) ? c.onAccent : c.text2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const SectionLabel('Zeitraum'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        _hourChip('Von', s.startHour, (int v) {
                          final StretchSettings n = _copy(s);
                          n.startHour = v;
                          if (n.endHour < v) {
                            n.endHour = v;
                          }
                          state.updateStretch(n);
                        }),
                        _hourChip('Bis', s.endHour, (int v) {
                          final StretchSettings n = _copy(s);
                          n.endHour = v;
                          if (n.startHour > v) {
                            n.startHour = v;
                          }
                          state.updateStretch(n);
                        }),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const SectionLabel('Wie oft'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        for (final int m in const <int>[30, 45, 60, 120])
                          InkWell(
                            onTap: () {
                              final StretchSettings n = _copy(s);
                              n.intervalMin = m;
                              state.updateStretch(n);
                            },
                            child: ChipBox(
                              text: m == 120 ? 'Alle 2 h' : 'Alle $m min',
                              selected: s.intervalMin == m,
                              height: 44,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
