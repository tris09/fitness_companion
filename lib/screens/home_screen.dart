import 'package:flutter/material.dart';

import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'chat_screen.dart';
import 'planner_screen.dart';
import 'settings_screen.dart';
import 'stretch_screen.dart';
import 'timer_screen.dart';
import '../training_memory.dart';

class HomeScreen extends StatelessWidget {
  final void Function(int index) onOpenTab;

  const HomeScreen({super.key, required this.onOpenTab});

  void _openSettings(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (BuildContext _) => const SettingsScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    final AppState state = AppScope.of(context);
    final Plan? plan = state.plans.isEmpty ? null : state.plans.first;
    final DateTime? next = state.nextReminder;

    return ListView(
      padding: EdgeInsets.zero,
      children: <Widget>[
        PageHeader(
          kicker: 'Dein Tag',
          title: 'Home',
          trailing: IconButton(
            tooltip: 'Einstellungen',
            onPressed: () => _openSettings(context),
            icon: Icon(Icons.settings_outlined, color: c.text2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const SectionLabel('Schnell erstellt'),
                    const SizedBox(height: 8),
                    Text('TRAINING FÜR HEUTE', style: heading(context, 30)),
                    const SizedBox(height: 6),
                    Text(
                      state.recentWorkouts().isEmpty
                          ? 'Der Coach plant nach deinem Profil und deinen Vorlieben.'
                          : 'Der Coach plant nach deinen ${state.recentWorkouts().length} Trainings der letzten 2 Wochen und deinen Vorlieben.',
                      style: bodyStyle(context, size: 14, color: c.text2),
                    ),
                    const SizedBox(height: 12),
                    PrimaryButton(
                      label: 'Jetzt erstellen',
                      icon: Icons.bolt,
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (BuildContext _) => const ChatScreen(
                              initialPrompt: 'Erstelle mir ein optimales Training für heute. '
                                  'Berücksichtige meine Trainings der letzten 2 Wochen, meine Vorlieben und meine Körperdaten.',
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const SectionLabel('Nächste Einheit'),
                    const SizedBox(height: 10),
                    if (plan != null) ...<Widget>[
                      Text(plan.name.toUpperCase(), style: heading(context, 34)),
                      const SizedBox(height: 8),
                      Text(
                        '${plan.items.length} Übungen · ca. ${plan.estimatedMinutes} min',
                        style: bodyStyle(context, size: 14, color: c.text2),
                      ),
                      const SizedBox(height: 14),
                      PrimaryButton(
                        label: 'Training starten',
                        onPressed: plan.items.isEmpty
                            ? null
                            : () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(builder: (BuildContext _) => TimerScreen(plan: plan)),
                                );
                              },
                      ),
                    ] else ...<Widget>[
                      Text('NOCH KEIN PLAN', style: heading(context, 34)),
                      const SizedBox(height: 14),
                      PrimaryButton(
                        label: 'Plan erstellen',
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(builder: (BuildContext _) => const PlannerScreen()),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _DueCard(state: state),
              _StretchTile(state: state, next: next),
              const SizedBox(height: 12),
              SecondaryButton(label: 'Alle Pläne', onPressed: () => onOpenTab(1)),
            ],
          ),
        ),
      ],
    );
  }
}

/// Tile on Heute that opens the stretch plan.
class _StretchTile extends StatelessWidget {
  final AppState state;
  final DateTime? next;

  const _StretchTile({required this.state, required this.next});

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    final int total = state.todayPlan.length;
    final int done = state.todayPlan.where((({DateTime time, Stretch stretch}) e) => state.stretchDone.contains(e.stretch.id)).length;
    final String status = total > 0 ? 'Heute $done von $total erledigt' : 'Push mit Dehnübungen über den Tag';
    return InkWell(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute<void>(builder: (BuildContext _) => const StretchScreen()));
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.surface,
          border: Border.all(color: c.border),
          borderRadius: BorderRadius.circular(kRadius),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 48,
              height: 48,
              color: c.accent,
              child: Icon(Icons.accessibility_new, color: c.onAccent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const SectionLabel('Dehnplan'),
                  const SizedBox(height: 4),
                  Text(status, style: bodyStyle(context, size: 15, weight: FontWeight.w700)),
                  if (next != null)
                    Text(reminderLabel(true, next), style: bodyStyle(context, size: 13, color: c.text2)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: c.text2),
          ],
        ),
      ),
    );
  }
}

/// Shows muscle groups that were not trained for a while, with a quick button.
class _DueCard extends StatelessWidget {
  final AppState state;

  const _DueCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    if (state.history.isEmpty) {
      return const SizedBox.shrink();
    }
    final List<String> due = state.dueMuscles.take(2).toList();
    if (due.isEmpty) {
      return const SizedBox.shrink();
    }
    final Map<String, DateTime> last = state.muscleLast;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const SectionLabel('Lange nicht trainiert'),
            const SizedBox(height: 8),
            for (final String g in due)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: <Widget>[
                    Expanded(child: Text(g.toUpperCase(), style: heading(context, 24))),
                    Text(agoText(last[g]), style: bodyStyle(context, size: 14, color: c.text2)),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            SecondaryButton(
              label: 'Training dafür erstellen',
              height: 46,
              fontSize: 17,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (BuildContext _) => ChatScreen(
                      initialPrompt: 'Erstelle mir ein Training für heute mit Schwerpunkt ${due.join(' und ')}. '
                          'Nutze meine letzten Gewichte für die Gewichtsempfehlungen.',
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
