import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/common.dart';
import '../wiki_content.dart';

/// Overview of the wiki. Reached from the coach, the tab bar stays the same.
class WikiScreen extends StatelessWidget {
  const WikiScreen({super.key});

  void _open(BuildContext context, WikiEntry entry) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (BuildContext _) => WikiDetailScreen(entry: entry)));
  }

  Widget _tile(BuildContext context, WikiEntry e, {bool highlight = false}) {
    final AppColors c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _open(context, e),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: c.surface,
            border: Border.all(color: highlight ? c.accent : c.border, width: highlight ? 2 : 1),
            borderRadius: BorderRadius.circular(kRadius),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(e.title.toUpperCase(), style: heading(context, 24)),
                    const SizedBox(height: 4),
                    Text(e.tagline, style: bodyStyle(context, size: 13, color: c.text2)),
                    const SizedBox(height: 8),
                    SectionLabel(e.level),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: c.text2),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const PageHeader(kicker: 'Wiki', title: 'Trainingsstile', showBack: true),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const SectionLabel('Zum Einstieg'),
                  const SizedBox(height: 8),
                  _tile(context, basicsEntry, highlight: true),
                  const SizedBox(height: 12),
                  const SectionLabel('Alle Stile'),
                  const SizedBox(height: 8),
                  for (final WikiEntry e in styleWiki) _tile(context, e),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WikiDetailScreen extends StatelessWidget {
  final WikiEntry entry;

  const WikiDetailScreen({super.key, required this.entry});

  Widget _list(BuildContext context, String label, List<String> items) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    final AppColors c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SectionLabel(label),
          const SizedBox(height: 8),
          for (final String t in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(top: 8, right: 10),
                    child: Container(width: 6, height: 6, color: c.accentText),
                  ),
                  Expanded(child: Text(t, style: bodyStyle(context, size: 15))),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    final bool basics = identical(entry, basicsEntry);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            PageHeader(kicker: entry.level, title: entry.title, showBack: true),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(entry.tagline, style: bodyStyle(context, size: 17, weight: FontWeight.w600)),
                  const SizedBox(height: 14),
                  Text(entry.what, style: bodyStyle(context, size: 15, color: c.text2)),
                  _list(context, basics ? 'Begriffe' : 'Für wen geeignet', entry.forWhom),
                  _list(context, 'Vorteile', entry.pros),
                  _list(context, basics ? 'Gut zu wissen' : 'Darauf achten', entry.watchOut),
                  if (entry.example.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 22),
                    const SectionLabel('Beispiel'),
                    const SizedBox(height: 8),
                    AppCard(child: Text(entry.example, style: bodyStyle(context, size: 15))),
                  ],
                  const SizedBox(height: 28),
                  Text(
                    'Allgemeine Hinweise, keine individuelle Trainings- oder Gesundheitsberatung. Bei Vorerkrankungen oder Beschwerden vorher ärztlich abklären.',
                    style: bodyStyle(context, size: 12, color: c.text3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
