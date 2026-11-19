import 'package:flutter/material.dart';

import '../state.dart';
import '../theme.dart';
import '../training_memory.dart';
import '../widgets/common.dart';
import '../widgets/day_planner.dart';
import '../widgets/home_blocks.dart';
import '../widgets/profile_sheet.dart';
import 'chat_screen.dart';
import 'home_edit_screen.dart';

class HomeScreen extends StatelessWidget {
  final void Function(int index) onOpenTab;

  /// Opens the food tab. Null when the food feature is off.
  final VoidCallback? onOpenFood;

  const HomeScreen({super.key, required this.onOpenTab, this.onOpenFood});

  /// First name as entered after login.
  static String firstName(AppState state) => state.firstName;

  Widget _block(BuildContext context, AppState state, String id) {
    switch (id) {
      case 'calendar':
        return const DayPlanner();
      case 'ad':
        return const AdCard();
      case 'tiles':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Expanded(child: SectionLabel('Deine Kacheln')),
                TextButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (BuildContext _) => const HomeEditScreen())),
                  child: Text('Anpassen', style: bodyStyle(context, size: 13, weight: FontWeight.w700)),
                ),
              ],
            ),
            HomeTiles(onOpenFood: onOpenFood),
            const SizedBox(height: 12),
            _DueCard(state: state),
          ],
        );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final AppState state = AppScope.of(context);
    final String name = firstName(state);

    return ListView(
      padding: EdgeInsets.zero,
      children: <Widget>[
        PageHeader(
          kicker: longDate(DateTime.now()),
          title: name.isEmpty ? 'Hi!' : 'Hi, $name',
          band: true,
          // Initial instead of the gear. Opens the profile sheet with all settings.
          trailing: ProfileAvatar(onTap: () => showProfileSheet(context)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (final String id in state.homeOrder) ...<Widget>[
                _block(context, state, id),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
        // News are always last and cannot be moved.
        if (state.features.news) const NewsSection(),
      ],
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
    if (state.history.isEmpty || !state.features.coach) {
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

