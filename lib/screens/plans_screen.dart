import 'package:flutter/material.dart';

import '../catalog.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';
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
        const PageHeader(kicker: 'Deine Trainingspläne', title: 'Pläne'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            children: <Widget>[
              if (state.plans.isEmpty)
                Text('Noch kein Plan vorhanden.', style: bodyStyle(context, color: c.text2)),
              for (final Plan plan in state.plans)
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
