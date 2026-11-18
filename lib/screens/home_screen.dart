import 'package:flutter/material.dart';

import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'planner_screen.dart';
import 'settings_screen.dart';
import 'timer_screen.dart';

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
          title: 'Heute',
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
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const SectionLabel('Dehnpausen'),
                    const SizedBox(height: 8),
                    Text(
                      reminderLabel(state.stretch.enabled, next),
                      style: bodyStyle(context, size: 15, weight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    SecondaryButton(label: 'Jetzt dehnen', onPressed: () => onOpenTab(2)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SecondaryButton(label: 'Alle Pläne', onPressed: () => onOpenTab(1)),
            ],
          ),
        ),
      ],
    );
  }
}
