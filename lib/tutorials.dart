/// One step of a tutorial. Shows one picture, a title, a text and an optional link.
class TutorialStep {
  final String title;
  final String text;

  /// Asset path of the picture, for example 'assets/tutorials/gemini_1.webp'.
  /// A missing file shows a placeholder, so the app never breaks.
  final String image;
  final String? linkLabel;
  final String? linkUrl;

  const TutorialStep({
    required this.title,
    required this.text,
    required this.image,
    this.linkLabel,
    this.linkUrl,
  });
}

class Tutorial {
  final String title;
  final List<TutorialStep> steps;

  const Tutorial({required this.title, required this.steps});
}

/// How to get a Gemini API key.
const Tutorial geminiKeyTutorial = Tutorial(
  title: 'API-Schlüssel',
  steps: <TutorialStep>[
    TutorialStep(
      title: 'Seite öffnen',
      text: 'Öffne die Seite für API-Schlüssel in Google AI Studio.',
      image: 'assets/tutorials/gemini_1.webp',
      linkLabel: 'aistudio.google.com/api-keys',
      linkUrl: 'https://aistudio.google.com/api-keys',
    ),
    TutorialStep(
      title: 'Schlüssel erstellen',
      text: 'Tippe auf „API-Schlüssel erstellen“.',
      image: 'assets/tutorials/gemini_2.webp',
    ),
    TutorialStep(
      title: 'Schlüssel benennen',
      text: 'Gib dem Schlüssel und dem Projekt einen Namen, zum Beispiel „Fitness Coach API“.',
      image: 'assets/tutorials/gemini_3.webp',
    ),
    TutorialStep(
      title: 'In die App einfügen',
      text: 'Kopiere den API-Schlüssel und füge ihn hier in der App ein.',
      image: 'assets/tutorials/gemini_4.webp',
    ),
  ],
);

/// Short tour on the first start. Text only, no pictures needed.
const Tutorial welcomeTutorial = Tutorial(
  title: 'Willkommen',
  steps: <TutorialStep>[
    TutorialStep(
      title: 'Wischen statt suchen',
      text: 'Unten findest du Home, Pläne, Coach und Essen. Du kannst auch einfach seitlich wischen.',
      image: '',
    ),
    TutorialStep(
      title: 'Pläne bauen',
      text: 'Im Tab Pläne baust du dein Training. Halte Sätze, Wiederholungen oder Pause gedrückt für den Drehwähler. '
          'Zwei Übungen verbunden ergeben ein Superset.',
      image: '',
    ),
    TutorialStep(
      title: 'Training läuft von selbst',
      text: 'Pausen, Zeitübungen, Aufwärmen und Cooldown zählen automatisch. Nur bei festen Wiederholungen tippst du auf Satz fertig.',
      image: '',
    ),
    TutorialStep(
      title: 'Dehnplan und Coach',
      text: 'Auf Home startest du den Dehnplan mit Erinnerungen über den Tag. Der Coach erstellt dir Pläne und Einkaufslisten, '
          'dafür brauchst du einen kostenlosen Gemini-Schlüssel.',
      image: '',
    ),
  ],
);
