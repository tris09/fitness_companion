import 'package:flutter/material.dart';

import '../state.dart';
import '../theme.dart';
import '../tutorials.dart';
import '../widgets/tutorial_dialog.dart';
import '../widgets/common.dart';
import 'coach_screen.dart';
import 'home_screen.dart';
import 'nutrition_screen.dart';
import 'plans_screen.dart';

/// Holds the four tabs and the bottom bar.
class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    // Short tour on the very first start.
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (!mounted) {
        return;
      }
      final AppState state = AppScope.of(context);
      if (!state.welcomeSeen) {
        state.markWelcomeSeen();
        showTutorial(context, welcomeTutorial);
      }
    });
  }

  /// Tabs change with a fade. Sideways slides are kept for the days on Home,
  /// so the two kinds of movement stay easy to tell apart.
  void _go(int i) {
    if (i == _index) {
      return;
    }
    setState(() {
      _index = i;
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    final AppState state = AppScope.of(context);
    // Tabs follow the chosen features. Home and Pläne are always there.
    final List<String> labels = <String>['Home', 'Pläne', if (state.features.coach) 'Coach', if (state.features.food) 'Essen'];
    if (_index >= labels.length) {
      _index = 0;
    }
    final int foodIndex = labels.indexOf('Essen');
    final List<Widget> pages = <Widget>[
      HomeScreen(onOpenTab: _go, onOpenFood: foodIndex < 0 ? null : () => _go(foodIndex)),
      const PlansScreen(),
      if (state.features.coach) CoachScreen(onOpenTab: _go),
      if (state.features.food) const NutritionScreen(),
    ];
    const Map<String, IconData> iconOf = <String, IconData>{
      'Home': Icons.home_outlined,
      'Pläne': Icons.calendar_month_outlined,
      'Coach': Icons.chat_bubble_outline,
      'Essen': Icons.restaurant,
    };
    final List<IconData> icons = labels.map((String l) => iconOf[l]!).toList();
    return Scaffold(
      // No top safe area here: the title bars of the tabs reach up under the status bar.
      body: Stack(
        children: <Widget>[
          for (int i = 0; i < pages.length; i++)
            Positioned.fill(
              key: ValueKey<String>(labels[i]),
              // The fade sits outside TickerMode. Inside it, a hidden tab paused its
              // own fade-out and stayed visible on top of the new tab.
              child: IgnorePointer(
                ignoring: i != _index,
                child: AnimatedOpacity(
                  opacity: i == _index ? 1 : 0,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  child: TickerMode(
                    enabled: i == _index,
                    child: ExcludeSemantics(
                      excluding: i != _index,
                      child: ColoredBox(color: c.bg, child: pages[i]),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: c.navBar,
          border: Border(top: BorderSide(color: c.border, width: c.borderWidth)),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: <Widget>[
              for (int i = 0; i < labels.length; i++)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: i == _index,
                    label: labels[i],
                    child: InkWell(
                      onTap: () => _go(i),
                      child: AnimatedContainer(
                        duration: kFast,
                        curve: kEase,
                        height: 66,
                        color: i == _index ? c.navActiveBg : Colors.transparent,
                        child: Stack(
                          children: <Widget>[
                            // Line on top of the active tab. Full width in light mode, short in dark mode.
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: FractionallySizedBox(
                                  widthFactor: c.navFullLine ? 1 : 0.4,
                                  child: AnimatedContainer(
                                    duration: kFast,
                                    curve: kEase,
                                    height: c.navFullLine ? 3 : 2,
                                    color: i == _index ? c.navLine : Colors.transparent,
                                  ),
                                ),
                              ),
                            ),
                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Icon(icons[i], size: 24, color: i == _index ? c.navActiveFg : c.text2),
                                  const SizedBox(height: 4),
                                  AnimatedDefaultTextStyle(
                                    duration: kFast,
                                    curve: kEase,
                                    style: bodyStyle(
                                      context,
                                      size: 11,
                                      weight: i == _index ? FontWeight.w700 : FontWeight.w600,
                                      color: i == _index ? c.navActiveFg : c.text2,
                                    ),
                                    child: Text(labels[i]),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class PlaceholderScreen extends StatelessWidget {
  final String kicker;
  final String title;
  final String text;

  const PlaceholderScreen({super.key, required this.kicker, required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        PageHeader(kicker: kicker, title: title),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(text, style: bodyStyle(context, size: 16, color: c.text2)),
        ),
      ],
    );
  }
}
