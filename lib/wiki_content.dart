/// One page of the wiki. Empty lists are not shown.
class WikiEntry {
  final String title;
  final String level;
  final String tagline;
  final String what;
  final List<String> forWhom;
  final List<String> pros;
  final List<String> watchOut;
  final String example;

  const WikiEntry({
    required this.title,
    required this.level,
    required this.tagline,
    required this.what,
    this.forWhom = const <String>[],
    this.pros = const <String>[],
    this.watchOut = const <String>[],
    this.example = '',
  });
}

/// Explains the basic words once, for people who start from zero.
const WikiEntry basicsEntry = WikiEntry(
  title: 'Grundbegriffe',
  level: 'Für alle',
  tagline: 'Die Wörter, die in jedem Plan vorkommen',
  what: 'Ein Trainingsplan besteht aus Übungen. Zu jeder Übung gehören Sätze, Wiederholungen und eine Pause.',
  forWhom: <String>[
    'Wiederholung (Wdh): ein kompletter Ablauf der Bewegung, zum Beispiel einmal beugen und strecken.',
    'Satz: mehrere Wiederholungen am Stück. 3 Sätze mit 10 Wdh heißt: 10 Wiederholungen, kurz Pause, und das dreimal.',
    'Pause: Erholungszeit zwischen den Sätzen. Kurze Pausen (30 bis 60 s) passen zu leichteren Übungen, längere (2 bis 3 min) zu schweren.',
    'Superset: zwei Übungen direkt nacheinander ohne Pause. Danach folgt die Pause.',
    'Dauer (s): Bei Übungen wie dem Plank zählt die Zeit statt der Wiederholungen.',
  ],
  watchOut: <String>[
    'Nimm am Anfang lieber ein Gewicht, mit dem du saubere Wiederholungen schaffst. Steigern kannst du später.',
    'Gelenkschmerzen sind kein normaler Trainingsreiz. Bei Beschwerden pausieren und ärztlich abklären lassen.',
  ],
);

const List<WikiEntry> styleWiki = <WikiEntry>[
  WikiEntry(
    title: 'Ganzkörper',
    level: 'Einsteiger',
    tagline: 'Alle großen Muskelgruppen in jeder Einheit',
    what:
        'Jede Einheit trainiert Beine, Rücken, Brust, Schultern und Rumpf. Üblich sind 2 bis 3 Einheiten pro Woche mit mindestens einem Ruhetag dazwischen.',
    forWhom: <String>['Einsteiger und Wiedereinsteiger', 'Alle mit wenig Zeit pro Woche'],
    pros: <String>[
      'Einfach zu planen und leicht zu verstehen',
      'Jede Muskelgruppe wird mehrmals pro Woche trainiert',
      'Ein verpasster Tag wirft den Plan nicht um',
    ],
    watchOut: <String>[
      'Einzelne Einheiten dauern länger, weil viele Übungen drankommen',
      'Zwischen zwei Einheiten genug Erholung einplanen',
    ],
    example: 'Kniebeuge, Bankdrücken, Rudern, Schulterdrücken, Plank',
  ),
  WikiEntry(
    title: 'Push / Pull / Beine',
    level: 'Mit Erfahrung',
    tagline: 'Drücken, Ziehen und Beine auf drei Tage verteilt',
    what:
        'Push-Tag: Brust, Schultern, Trizeps. Pull-Tag: Rücken und Bizeps. Beintag: Beine und Gesäß. Der Plan läuft mit 3 bis 6 Trainingstagen pro Woche.',
    forWhom: <String>['Alle mit etwas Trainingserfahrung', 'Wer mindestens drei feste Trainingstage hat'],
    pros: <String>[
      'Mehr Übungen pro Muskelgruppe als im Ganzkörperplan',
      'Klare Struktur, leicht zu merken',
      'Die Muskeln erholen sich, während andere trainieren',
    ],
    watchOut: <String>['Mit nur zwei Tagen pro Woche fehlen Muskelgruppen', 'Ein verpasster Tag verschiebt die Reihenfolge'],
    example: 'Push: Bankdrücken, Schulterdrücken. Pull: Klimmzug, Rudern. Beine: Kniebeuge, Rumänisches Kreuzheben',
  ),
  WikiEntry(
    title: 'Oberkörper / Unterkörper',
    level: 'Einsteiger bis Mittel',
    tagline: 'Zwei Tage im Wechsel',
    what:
        'An einem Tag trainierst du den Oberkörper, am nächsten Beine und Hüfte. Mit vier Tagen pro Woche kommt jede Muskelgruppe etwa zweimal dran.',
    forWhom: <String>['Alle, die 3 bis 4 Tage pro Woche trainieren', 'Wer mehr Umfang will als im Ganzkörperplan'],
    pros: <String>['Gute Balance zwischen Aufwand und Erholung', 'Gut kombinierbar mit Hanteln und Geräten'],
    watchOut: <String>['Die Oberkörpertage können lang werden', 'Den Rumpf nicht vergessen'],
    example: 'Oberkörper: Bankdrücken, Rudern, Schulterdrücken. Unterkörper: Kniebeuge, Beinbeuger, Wadenheben',
  ),
  WikiEntry(
    title: 'CrossFit',
    level: 'Mit Erfahrung',
    tagline: 'Funktionelle Bewegungen mit hoher Intensität',
    what:
        'Eine Mischung aus Gewichtheben, Turnen und Ausdauer. Die Übungen werden oft als Zirkel oder auf Zeit trainiert, meist mit wenig Pause dazwischen.',
    forWhom: <String>['Wer abwechslungsreiches, forderndes Training mag', 'Alle mit solider Grundfitness'],
    pros: <String>[
      'Trainiert Kraft, Ausdauer und Beweglichkeit gleichzeitig',
      'Abwechslungsreich und zeiteffizient',
    ],
    watchOut: <String>[
      'Erst saubere Technik, dann Tempo',
      'Bei Müdigkeit steigt das Verletzungsrisiko: lieber leichter bleiben',
      'Neue Bewegungen mit leichtem Gewicht lernen',
    ],
    example: 'Burpees, Kettlebell Swings, Box Jumps, Wall Balls, Rudern',
  ),
  WikiEntry(
    title: 'Supersets',
    level: 'Mit etwas Erfahrung',
    tagline: 'Zwei Übungen direkt hintereinander',
    what:
        'Du machst zwei Übungen ohne Pause nacheinander und ruhst dich erst danach aus. Häufig sind das Gegenspieler, zum Beispiel Brust und Rücken.',
    forWhom: <String>['Alle mit wenig Zeit', 'Wer sein Training dichter machen will'],
    pros: <String>['Spart Zeit', 'Hält den Puls höher', 'Ideal für Gegenspieler-Paare'],
    watchOut: <String>[
      'Durch die Ermüdung musst du eventuell das Gewicht senken',
      'Im vollen Studio zwei Geräte gleichzeitig zu belegen ist schwierig. Nimm Hanteln.',
    ],
    example: 'Bankdrücken direkt gefolgt von Rudern, danach 90 s Pause',
  ),
  WikiEntry(
    title: 'Freie Gewichte',
    level: 'Einsteiger mit Anleitung',
    tagline: 'Kurzhanteln, Langhantel und Kettlebell',
    what:
        'Du bewegst das Gewicht frei, ohne Führung durch eine Maschine. Dadurch arbeiten viele Muskeln gleichzeitig mit, vor allem die stabilisierenden.',
    forWhom: <String>['Wer Kraft und Koordination aufbauen will', 'Auch gut für zu Hause mit wenig Ausrüstung'],
    pros: <String>['Sehr vielseitig', 'Trainiert viele Muskeln gleichzeitig', 'Gewicht lässt sich fein steigern'],
    watchOut: <String>[
      'Technik ist wichtig: am Anfang leicht beginnen',
      'Bei schweren Gewichten Hantelbank mit Fangarmen nutzen oder einen Partner zum Sichern',
    ],
    example: 'Kniebeuge, Kreuzheben, Kurzhantel-Rudern, Schulterdrücken',
  ),
  WikiEntry(
    title: 'Gerätetraining',
    level: 'Einsteiger',
    tagline: 'Geführte Bewegung an Maschinen',
    what: 'Die Maschine gibt den Bewegungsweg vor. Du stellst Sitz und Gewicht ein und drückst oder ziehst.',
    forWhom: <String>['Einsteiger im Studio', 'Wer einzelne Muskeln gezielt trainieren will'],
    pros: <String>['Leicht zu lernen', 'Gute Kontrolle, auch ohne Partner', 'Gewicht schnell wechselbar'],
    watchOut: <String>[
      'Sitz und Polster auf deine Körpergröße einstellen',
      'Stabilisierende Muskeln werden weniger gefordert',
      'Du brauchst ein Studio',
    ],
    example: 'Beinpresse, Brustpresse, Latzug, Sitzendes Rudern',
  ),
  WikiEntry(
    title: 'Calisthenics',
    level: 'Einsteiger bis Mittel',
    tagline: 'Training mit dem eigenen Körpergewicht',
    what:
        'Übungen wie Liegestütze, Klimmzüge, Dips und Kniebeugen. Du brauchst kaum Ausrüstung. Die Schwierigkeit steigt über schwerere Varianten.',
    forWhom: <String>['Wer überall trainieren möchte', 'Alle, die Körperbeherrschung aufbauen wollen'],
    pros: <String>['Kostenlos und ortsunabhängig', 'Schult Körperspannung und Kontrolle'],
    watchOut: <String>[
      'Klimmzüge und Dips brauchen eine Stange oder Barren',
      'Beine lassen sich mit dem Körpergewicht schwerer steigern',
      'Mit leichten Varianten beginnen, zum Beispiel Liegestütze auf den Knien',
    ],
    example: 'Liegestütze, Ausfallschritte, Klimmzüge, Dips, Plank',
  ),
  WikiEntry(
    title: 'Kraft & Power',
    level: 'Mit Erfahrung',
    tagline: 'Schwere Grundübungen, wenig Wiederholungen',
    what:
        'Der Fokus liegt auf maximaler Kraft: schwere Gewichte, meist 1 bis 6 Wiederholungen pro Satz und lange Pausen von 2 bis 5 Minuten bei Grundübungen wie Kniebeuge, Kreuzheben, Bankdrücken und Schulterdrücken.',
    forWhom: <String>['Fortgeschrittene, die Kraft aufbauen wollen', 'Wer die Technik der Grundübungen sicher beherrscht'],
    pros: <String>['Deutliche Kraftzuwächse', 'Klare, messbare Ziele'],
    watchOut: <String>[
      'Hohe Belastung für Gelenke und Erholung',
      'Gründlich aufwärmen, Technik geht vor Gewicht',
      'Pausen einhalten, sonst sinkt die Leistung',
    ],
    example: 'Kniebeuge 5 × 5, Bankdrücken 5 × 5, Kreuzheben 3 × 5',
  ),
];
