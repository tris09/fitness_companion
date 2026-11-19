import 'package:flutter/material.dart';

import '../models.dart';
import '../screens/progress_screen.dart';
import '../screens/stretch_screen.dart';
import '../screens/tracking_screen.dart';
import '../services/news_service.dart';
import '../state.dart';
import '../theme.dart';
import 'common.dart';

/// Dashed outline, used for the ad and for drop areas.
class DashedBorder extends CustomPainter {
  final Color color;
  final double width;

  DashedBorder({required this.color, this.width = 1.5});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint p = Paint()
      ..color = color
      ..strokeWidth = width
      ..style = PaintingStyle.stroke;
    const double dash = 6;
    const double gap = 4;
    void line(Offset a, Offset b) {
      final double len = (b - a).distance;
      final Offset dir = (b - a) / len;
      double d = 0;
      while (d < len) {
        final double e = (d + dash).clamp(0, len).toDouble();
        canvas.drawLine(a + dir * d, a + dir * e, p);
        d += dash + gap;
      }
    }

    final double h = width / 2;
    line(Offset(h, h), Offset(size.width - h, h));
    line(Offset(size.width - h, h), Offset(size.width - h, size.height - h));
    line(Offset(size.width - h, size.height - h), Offset(h, size.height - h));
    line(Offset(h, size.height - h), Offset(h, h));
  }

  @override
  bool shouldRepaint(DashedBorder old) => old.color != color || old.width != width;
}

/// Ad slot. Always on Home; it can be moved but not removed.
class AdCard extends StatelessWidget {
  const AdCard({super.key});

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    return CustomPaint(
      painter: DashedBorder(color: c.border, width: c.borderWidth),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: <Widget>[
            Container(width: 46, height: 46, color: c.surface2, child: Icon(Icons.shopping_bag_outlined, color: c.text2)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(border: Border.all(color: c.border)),
                    child: Text('ANZEIGE', style: labelStyle(context)),
                  ),
                  const SizedBox(height: 4),
                  Text('PARTNER-EMPFEHLUNG', style: heading(context, 18)),
                  Text('Platzhalter. Hier erscheint später eine Anzeige.', style: bodyStyle(context, size: 12, color: c.text2)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The small tiles on Home. Which ones show depends on the chosen features.
class HomeTiles extends StatelessWidget {
  final VoidCallback? onOpenFood;

  const HomeTiles({super.key, this.onOpenFood});

  @override
  Widget build(BuildContext context) {
    final AppState state = AppScope.of(context);
    final AppFeatures f = state.features;
    final List<Widget> tiles = <Widget>[
      _Tile(
        label: 'Woche',
        big: '${state.workoutsThisWeek} von ${state.weekGoal}',
        small: state.streak > 0 ? 'Serie ${state.streak} ${state.streak == 1 ? 'Woche' : 'Wochen'}' : 'Statistik ansehen',
        onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (BuildContext _) => const ProgressScreen())),
      ),
      if (f.tracking)
        _Tile(
          label: 'Tracking',
          big: state.lastBody == null ? '–' : formatKg(state.lastBody!.weightKg),
          small: state.bodyDue ? 'Fällig · heute eintragen' : 'Eingetragen',
          highlight: state.bodyDue,
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (BuildContext _) => const TrackingScreen())),
        ),
      if (f.stretch)
        _Tile(
          label: 'Dehnen',
          big: state.todayPlan.isEmpty
              ? 'Aus'
              : '${state.todayPlan.where((({DateTime time, Stretch stretch}) e) => state.stretchDone.contains(e.stretch.id)).length} von ${state.todayPlan.length}',
          small: state.todayPlan.isEmpty ? 'Dehnplan einrichten' : 'Heute erledigt',
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (BuildContext _) => const StretchScreen())),
        ),
      if (f.food)
        _Tile(
          label: 'Einkauf',
          big: state.shopping.isEmpty ? '–' : '${state.shopping.first.items.where((ShoppingItem i) => !i.done).length} offen',
          small: state.shopping.isEmpty ? 'Liste erstellen' : state.shopping.first.title,
          onTap: onOpenFood,
        ),
    ];
    final List<Widget> rows = <Widget>[];
    for (int i = 0; i < tiles.length; i += 2) {
      rows.add(Padding(
        padding: EdgeInsets.only(bottom: i + 2 < tiles.length ? 10 : 0),
        child: Row(
          children: <Widget>[
            Expanded(child: tiles[i]),
            const SizedBox(width: 10),
            Expanded(child: i + 1 < tiles.length ? tiles[i + 1] : const SizedBox()),
          ],
        ),
      ));
    }
    return Column(children: rows);
  }
}

class _Tile extends StatelessWidget {
  final String label;
  final String big;
  final String small;
  final String? badge;
  final VoidCallback? onTap;

  /// Whole tile in lime, e.g. when body data are due. Goes back to normal
  /// as soon as the condition is gone (a new entry is saved).
  final bool highlight;

  const _Tile({required this.label, required this.big, required this.small, this.badge, this.onTap, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    final Color ink = AppColors.of(context).onLime;
    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: kFast,
        curve: kEase,
        height: 108,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: highlight ? c.lime : c.surface,
          // Lime blocks have no extra border (also in high contrast).
          border: Border.all(color: highlight ? c.lime : c.border, width: c.borderWidth),
          borderRadius: BorderRadius.circular(kRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(child: SectionLabel(label, color: highlight ? ink : null)),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    color: c.lime,
                    child: Text(badge!.toUpperCase(), style: labelStyle(context, color: AppColors.of(context).onLime)),
                  ),
              ],
            ),
            const Spacer(),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(big.toUpperCase(), style: heading(context, 24, color: highlight ? ink : null)),
            ),
            Text(
              small,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: bodyStyle(context, size: 12, color: highlight ? ink : c.text2, weight: highlight ? FontWeight.w600 : FontWeight.w400),
            ),
          ],
        ),
      ),
    );
  }
}

/// News at the very bottom of Home. Own background and a strong line on top,
/// so it is clear where the news begin. Not movable.
class NewsSection extends StatelessWidget {
  final int count;

  const NewsSection({super.key, this.count = 3});

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      // Same background as the page, no divider line on top.
      color: c.bg,
      child: FutureBuilder<List<NewsItem>>(
        future: newsSource.latest(),
        builder: (BuildContext context, AsyncSnapshot<List<NewsItem>> snap) {
          final List<NewsItem> items = (snap.data ?? <NewsItem>[]).take(count).toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    color: c.text,
                    child: Text('NEWS', style: labelStyle(context, color: c.bg)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text('Fitness und Gesundheit', style: bodyStyle(context, size: 12, color: c.text3))),
                  if (count < 5)
                    TextButton(
                      onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (BuildContext _) => const NewsScreen())),
                      child: Text('Alle ›', style: bodyStyle(context, size: 13, weight: FontWeight.w700)),
                    ),
                ],
              ),
              for (final NewsItem n in items)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(border: Border(top: BorderSide(color: c.border))),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(width: 60, height: 60, color: c.border.withOpacity(0.6)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(n.category.toUpperCase(), style: labelStyle(context)),
                            const SizedBox(height: 2),
                            Text(n.title, style: bodyStyle(context, size: 14, weight: FontWeight.w600)),
                            Text('${n.source} · ${n.age}', style: bodyStyle(context, size: 11, color: c.text3)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 6),
              Text('Platzhalter. Später geladen von unserem Server.', style: bodyStyle(context, size: 11, color: c.text3)),
            ],
          );
        },
      ),
    );
  }
}

class NewsScreen extends StatelessWidget {
  const NewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: const <Widget>[
            PageHeader(kicker: 'Platzhalter, ohne Server', title: 'News', showBack: true),
            NewsSection(count: 20),
          ],
        ),
      ),
    );
  }
}
