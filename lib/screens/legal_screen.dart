import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/common.dart';

/// Privacy notes and imprint. Text in [brackets] must be filled in before a release.
/// This is a draft that describes what the app does, not legal advice.
class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key});

  static const List<(String, String)> _sections = <(String, String)>[
    (
      'Impressum',
      '[NAME]\n[STRASSE HAUSNUMMER]\n[PLZ ORT]\n[LAND]\nE-Mail: [E-MAIL]',
    ),
    (
      'Was die App speichert',
      'Pläne, Trainingsverlauf, Gewichte, Körperdaten, Coach-Chat, Einkaufslisten und Einstellungen '
          'werden nur auf diesem Handy gespeichert. Der Trainingsverlauf wird nach 2 Wochen gelöscht, '
          'die letzten 5 Trainings bleiben erhalten. Passwörter werden nur als Prüfwert (Hash) gespeichert.',
    ),
    (
      'KI-Coach (Google Gemini)',
      'Wenn du den Coach nutzt, schickt die App deine Anfrage zusammen mit Profil, Körperdaten, '
          'den letzten Trainings, Gewichten und gemerkten Vorlieben an Google Gemini. '
          'Dafür wird dein eigener API-Schlüssel verwendet. Es gelten die Bedingungen von Google. '
          'Ohne Schlüssel wird nichts gesendet.',
    ),
    (
      'Angebotssuche',
      'Wenn du einen Ort einträgst und nach Einkauf fragst, sucht Gemini mit der Google-Suche nach '
          'Angeboten in diesem Ort. Dabei werden Ort und bevorzugte Märkte gesendet.',
    ),
    (
      'Benachrichtigungen',
      'Erinnerungen für den Dehnplan werden auf dem Handy geplant. Dafür werden keine Daten gesendet.',
    ),
    (
      'Deine Rechte',
      'Unter Einstellungen kannst du alle Daten exportieren und alles löschen. '
          'Fragen an: [E-MAIL]',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const PageHeader(kicker: 'Rechtliches', title: 'Datenschutz', showBack: true),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  for (final (String, String) s in _sections) ...<Widget>[
                    SectionLabel(s.$1),
                    const SizedBox(height: 6),
                    Text(s.$2, style: bodyStyle(context, size: 15, color: c.text2)),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
