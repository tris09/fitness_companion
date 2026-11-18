import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/common.dart';
import 'coach_screen.dart';
import 'home_screen.dart';
import 'plans_screen.dart';
import 'stretch_screen.dart';

/// Holds the five tabs and the bottom bar.
class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _index = 0;

  void _go(int i) {
    setState(() {
      _index = i;
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    final List<Widget> pages = <Widget>[
      HomeScreen(onOpenTab: _go),
      const PlansScreen(),
      const StretchScreen(),
      CoachScreen(onOpenTab: _go),
      const PlaceholderScreen(kicker: 'Kommt später', title: 'Ernährung', text: 'Hier stehen später Tagesbedarf und Einkaufsliste.'),
    ];
    const List<String> labels = <String>['Heute', 'Pläne', 'Dehnen', 'Coach', 'Essen'];
    const List<IconData> icons = <IconData>[
      Icons.home_outlined,
      Icons.list_alt,
      Icons.accessibility_new,
      Icons.chat_bubble_outline,
      Icons.restaurant,
    ];
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            for (int i = 0; i < pages.length; i++) _TabFade(active: i == _index, child: pages[i]),
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

/// Keeps a tab alive and fades it in or out when the user switches tabs.
class _TabFade extends StatefulWidget {
  final bool active;
  final Widget child;

  const _TabFade({required this.active, required this.child});

  @override
  State<_TabFade> createState() => _TabFadeState();
}

class _TabFadeState extends State<_TabFade> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
    value: widget.active ? 1 : 0,
  );
  late final Animation<double> _curve = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
  late final Animation<Offset> _slide = Tween<Offset>(begin: const Offset(0, 0.02), end: Offset.zero).animate(_curve);

  @override
  void didUpdateWidget(_TabFade old) {
    super.didUpdateWidget(old);
    if (widget.active != old.active) {
      if (widget.active) {
        _ctrl.forward();
      } else {
        _ctrl.reverse();
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      child: widget.child,
      builder: (BuildContext _, Widget? child) {
        return Offstage(
          offstage: _ctrl.isDismissed,
          child: TickerMode(
            enabled: !_ctrl.isDismissed,
            child: IgnorePointer(
              ignoring: !widget.active,
              child: FadeTransition(
                opacity: _curve,
                child: SlideTransition(position: _slide, child: child),
              ),
            ),
          ),
        );
      },
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
