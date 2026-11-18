import 'package:flutter/material.dart';

import '../theme.dart';
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
  final PageController _pages = PageController();

  /// True while a tap on the bar moves the pages. Then the bar ignores the pages in between.
  bool _moving = false;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  /// Slides to a tab. Far jumps skip the pages in between, so the move stays short.
  Future<void> _go(int i) async {
    if (i == _index) {
      return;
    }
    final int from = _index;
    setState(() {
      _index = i;
    });
    _moving = true;
    if ((i - from).abs() > 1) {
      _pages.jumpToPage(i > from ? i - 1 : i + 1);
    }
    await _pages.animateToPage(i, duration: const Duration(milliseconds: 280), curve: kEase);
    _moving = false;
  }

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    final List<Widget> pages = <Widget>[
      HomeScreen(onOpenTab: _go),
      const PlansScreen(),
      CoachScreen(onOpenTab: _go),
      const NutritionScreen(),
    ];
    const List<String> labels = <String>['Home', 'Pläne', 'Coach', 'Essen'];
    const List<IconData> icons = <IconData>[
      Icons.home_outlined,
      Icons.list_alt,
      Icons.chat_bubble_outline,
      Icons.restaurant,
    ];
    return Scaffold(
      body: SafeArea(
        bottom: false,
        // Swipe sideways between the tabs. Each tab keeps its state.
        child: PageView(
          controller: _pages,
          onPageChanged: (int i) {
            if (!_moving && i != _index) {
              setState(() {
                _index = i;
              });
            }
          },
          children: <Widget>[
            for (final Widget p in pages) _KeepAlive(child: p),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: c.bg,
          border: Border(top: BorderSide(color: c.border)),
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
                    child: InkWell(
                      onTap: () => _go(i),
                      child: SizedBox(
                        height: 68,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            // The active tab gets a filled field behind the icon.
                            // Black with lime in light mode, lime with black in dark mode.
                            AnimatedContainer(
                              duration: kFast,
                              curve: kEase,
                              width: 52,
                              height: 32,
                              decoration: BoxDecoration(
                                color: i == _index ? c.accent : Colors.transparent,
                                borderRadius: BorderRadius.circular(kRadius),
                              ),
                              child: Icon(icons[i], size: 24, color: i == _index ? c.onAccent : c.text2),
                            ),
                            const SizedBox(height: 4),
                            AnimatedDefaultTextStyle(
                              duration: kFast,
                              curve: kEase,
                              style: bodyStyle(
                                context,
                                size: 11,
                                weight: i == _index ? FontWeight.w700 : FontWeight.w600,
                                color: i == _index ? c.text : c.text2,
                              ),
                              child: Text(labels[i]),
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

/// Keeps a tab alive while it is out of view in the page view.
class _KeepAlive extends StatefulWidget {
  final Widget child;

  const _KeepAlive({required this.child});

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
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
