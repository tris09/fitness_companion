/// One step of a tutorial. Shows one picture, a title, a text and an optional link.
class TutorialStep {
  final String title;
  final String text;

  /// Asset path of the picture, for example 'assets/tutorials/gemini_1.png'.
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
      image: 'assets/tutorials/gemini_1.png',
      linkLabel: 'aistudio.google.com/api-keys',
      linkUrl: 'https://aistudio.google.com/api-keys',
    ),
    TutorialStep(
      title: 'Schlüssel erstellen',
      text: 'Tippe auf „API-Schlüssel erstellen“.',
      image: 'assets/tutorials/gemini_2.png',
    ),
    TutorialStep(
      title: 'Schlüssel benennen',
      text: 'Gib dem Schlüssel und dem Projekt einen Namen, zum Beispiel „Fitness Coach API“.',
      image: 'assets/tutorials/gemini_3.png',
    ),
    TutorialStep(
      title: 'In die App einfügen',
      text: 'Kopiere den API-Schlüssel und füge ihn hier in der App ein.',
      image: 'assets/tutorials/gemini_4.png',
    ),
  ],
);
