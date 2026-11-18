import 'dart:math';

import 'models.dart';

const List<Exercise> exerciseCatalog = <Exercise>[
  Exercise(
    id: 'squat',
    name: 'Kniebeuge',
    muscleLabel: 'Beine, Gesäß',
    category: 'Beine',
    equipment: 'Freie Gewichte',
    muscles: <Muscle>[Muscle.quads, Muscle.hips],
  ),
  Exercise(
    id: 'lunge',
    name: 'Ausfallschritt',
    muscleLabel: 'Beine, Gesäß',
    category: 'Beine',
    equipment: 'Körpergewicht',
    muscles: <Muscle>[Muscle.quads, Muscle.hips],
  ),
  Exercise(
    id: 'rdl',
    name: 'Rumänisches Kreuzheben',
    muscleLabel: 'Beinrückseite, Gesäß',
    category: 'Beine',
    equipment: 'Freie Gewichte',
    muscles: <Muscle>[Muscle.hips, Muscle.quads],
  ),
  Exercise(
    id: 'legpress',
    name: 'Beinpresse',
    muscleLabel: 'Beine, Gesäß',
    category: 'Beine',
    equipment: 'Gerät',
    muscles: <Muscle>[Muscle.quads, Muscle.hips],
  ),
  Exercise(
    id: 'legext',
    name: 'Beinstrecker',
    muscleLabel: 'Oberschenkel vorne',
    category: 'Beine',
    equipment: 'Gerät',
    muscles: <Muscle>[Muscle.quads],
  ),
  Exercise(
    id: 'legcurl',
    name: 'Beinbeuger',
    muscleLabel: 'Oberschenkel hinten',
    category: 'Beine',
    equipment: 'Gerät',
    muscles: <Muscle>[Muscle.quads],
  ),
  Exercise(
    id: 'calf',
    name: 'Wadenheben',
    muscleLabel: 'Waden',
    category: 'Beine',
    equipment: 'Körpergewicht',
    muscles: <Muscle>[Muscle.calves],
  ),
  Exercise(
    id: 'bench',
    name: 'Bankdrücken',
    muscleLabel: 'Brust, Trizeps',
    category: 'Brust',
    equipment: 'Freie Gewichte',
    muscles: <Muscle>[Muscle.chest, Muscle.arms],
  ),
  Exercise(
    id: 'inclinedb',
    name: 'Schrägbankdrücken',
    muscleLabel: 'Obere Brust',
    category: 'Brust',
    equipment: 'Freie Gewichte',
    muscles: <Muscle>[Muscle.chest, Muscle.shoulders],
  ),
  Exercise(
    id: 'pushup',
    name: 'Liegestütz',
    muscleLabel: 'Brust, Trizeps',
    category: 'Brust',
    equipment: 'Körpergewicht',
    muscles: <Muscle>[Muscle.chest, Muscle.arms],
  ),
  Exercise(
    id: 'chestpress',
    name: 'Brustpresse',
    muscleLabel: 'Brust, Trizeps',
    category: 'Brust',
    equipment: 'Gerät',
    muscles: <Muscle>[Muscle.chest, Muscle.arms],
  ),
  Exercise(
    id: 'fly',
    name: 'Butterfly',
    muscleLabel: 'Brust',
    category: 'Brust',
    equipment: 'Gerät',
    muscles: <Muscle>[Muscle.chest],
  ),
  Exercise(
    id: 'deadlift',
    name: 'Kreuzheben',
    muscleLabel: 'Rücken, Gesäß',
    category: 'Rücken',
    equipment: 'Freie Gewichte',
    muscles: <Muscle>[Muscle.hips, Muscle.core],
  ),
  Exercise(
    id: 'row',
    name: 'Langhantelrudern',
    muscleLabel: 'Rücken, Bizeps',
    category: 'Rücken',
    equipment: 'Freie Gewichte',
    muscles: <Muscle>[Muscle.shoulders, Muscle.arms],
  ),
  Exercise(
    id: 'dbrow',
    name: 'Kurzhantelrudern',
    muscleLabel: 'Rücken, Bizeps',
    category: 'Rücken',
    equipment: 'Freie Gewichte',
    muscles: <Muscle>[Muscle.shoulders, Muscle.arms],
  ),
  Exercise(
    id: 'pullup',
    name: 'Klimmzug',
    muscleLabel: 'Rücken, Bizeps',
    category: 'Rücken',
    equipment: 'Körpergewicht',
    muscles: <Muscle>[Muscle.shoulders, Muscle.arms],
  ),
  Exercise(
    id: 'latpull',
    name: 'Latzug',
    muscleLabel: 'Rücken, Bizeps',
    category: 'Rücken',
    equipment: 'Gerät',
    muscles: <Muscle>[Muscle.shoulders, Muscle.arms],
  ),
  Exercise(
    id: 'seatedrow',
    name: 'Rudern am Kabel',
    muscleLabel: 'Rücken',
    category: 'Rücken',
    equipment: 'Gerät',
    muscles: <Muscle>[Muscle.shoulders, Muscle.arms],
  ),
  Exercise(
    id: 'ohp',
    name: 'Schulterdrücken',
    muscleLabel: 'Schultern',
    category: 'Schultern',
    equipment: 'Freie Gewichte',
    muscles: <Muscle>[Muscle.shoulders, Muscle.arms],
  ),
  Exercise(
    id: 'lateral',
    name: 'Seitheben',
    muscleLabel: 'Schultern',
    category: 'Schultern',
    equipment: 'Freie Gewichte',
    muscles: <Muscle>[Muscle.shoulders],
  ),
  Exercise(
    id: 'shoulderpress',
    name: 'Schulterpresse',
    muscleLabel: 'Schultern',
    category: 'Schultern',
    equipment: 'Gerät',
    muscles: <Muscle>[Muscle.shoulders, Muscle.arms],
  ),
  Exercise(
    id: 'facepull',
    name: 'Face Pull',
    muscleLabel: 'Hintere Schulter',
    category: 'Schultern',
    equipment: 'Gerät',
    muscles: <Muscle>[Muscle.shoulders],
  ),
  Exercise(
    id: 'curl',
    name: 'Bizeps-Curl',
    muscleLabel: 'Bizeps',
    category: 'Arme',
    equipment: 'Freie Gewichte',
    muscles: <Muscle>[Muscle.arms],
  ),
  Exercise(
    id: 'hammer',
    name: 'Hammer-Curl',
    muscleLabel: 'Bizeps, Unterarm',
    category: 'Arme',
    equipment: 'Freie Gewichte',
    muscles: <Muscle>[Muscle.arms],
  ),
  Exercise(
    id: 'dips',
    name: 'Dips',
    muscleLabel: 'Trizeps, Brust',
    category: 'Arme',
    equipment: 'Körpergewicht',
    muscles: <Muscle>[Muscle.arms, Muscle.chest],
  ),
  Exercise(
    id: 'pushdown',
    name: 'Trizepsdrücken am Kabel',
    muscleLabel: 'Trizeps',
    category: 'Arme',
    equipment: 'Gerät',
    muscles: <Muscle>[Muscle.arms],
  ),
  Exercise(
    id: 'plank',
    name: 'Plank',
    muscleLabel: 'Core',
    category: 'Core',
    equipment: 'Körpergewicht',
    muscles: <Muscle>[Muscle.core],
    timed: true,
  ),
  Exercise(
    id: 'crunch',
    name: 'Crunch',
    muscleLabel: 'Core',
    category: 'Core',
    equipment: 'Körpergewicht',
    muscles: <Muscle>[Muscle.core],
  ),
  Exercise(
    id: 'legraise',
    name: 'Beinheben',
    muscleLabel: 'Unterer Bauch',
    category: 'Core',
    equipment: 'Körpergewicht',
    muscles: <Muscle>[Muscle.core, Muscle.hips],
  ),
  Exercise(
    id: 'russian',
    name: 'Russian Twist',
    muscleLabel: 'Seitlicher Bauch',
    category: 'Core',
    equipment: 'Körpergewicht',
    muscles: <Muscle>[Muscle.core],
  ),
  Exercise(
    id: 'swing',
    name: 'Kettlebell-Swing',
    muscleLabel: 'Gesäß, Rücken',
    category: 'Ganzkörper',
    equipment: 'CrossFit',
    muscles: <Muscle>[Muscle.hips, Muscle.core, Muscle.shoulders],
  ),
  Exercise(
    id: 'burpee',
    name: 'Burpees',
    muscleLabel: 'Ganzkörper',
    category: 'Ganzkörper',
    equipment: 'CrossFit',
    muscles: <Muscle>[Muscle.shoulders, Muscle.chest, Muscle.core, Muscle.arms, Muscle.hips, Muscle.quads, Muscle.calves],
  ),
  Exercise(
    id: 'thruster',
    name: 'Thruster',
    muscleLabel: 'Beine, Schultern',
    category: 'Ganzkörper',
    equipment: 'CrossFit',
    muscles: <Muscle>[Muscle.quads, Muscle.hips, Muscle.shoulders, Muscle.arms],
  ),
  Exercise(
    id: 'wallball',
    name: 'Wall Ball',
    muscleLabel: 'Beine, Schultern',
    category: 'Ganzkörper',
    equipment: 'CrossFit',
    muscles: <Muscle>[Muscle.quads, Muscle.hips, Muscle.shoulders],
  ),
  Exercise(
    id: 'boxjump',
    name: 'Box Jump',
    muscleLabel: 'Beine',
    category: 'Ganzkörper',
    equipment: 'CrossFit',
    muscles: <Muscle>[Muscle.quads, Muscle.calves, Muscle.hips],
  ),
  Exercise(
    id: 'rope',
    name: 'Seilspringen',
    muscleLabel: 'Waden, Ausdauer',
    category: 'Ganzkörper',
    equipment: 'CrossFit',
    muscles: <Muscle>[Muscle.calves],
    timed: true,
  ),
  Exercise(
    id: 'rowerg',
    name: 'Rudergerät',
    muscleLabel: 'Ausdauer, Rücken',
    category: 'Ganzkörper',
    equipment: 'CrossFit',
    muscles: <Muscle>[Muscle.quads, Muscle.shoulders, Muscle.arms, Muscle.core],
    timed: true,
  ),
];

const List<String> exerciseCategories = <String>['Alle', 'Beine', 'Brust', 'Rücken', 'Schultern', 'Arme', 'Core', 'Ganzkörper'];

/// Training styles offered by the coach and the templates.
const List<String> trainingStyles = <String>[
  'Ganzkörper',
  'Push / Pull / Beine',
  'Oberkörper / Unterkörper',
  'CrossFit',
  'Supersets',
  'Freie Gewichte',
  'Gerätetraining',
  'Calisthenics',
  'Kraft & Power',
];

bool exerciseExists(String id) {
  for (final Exercise e in exerciseCatalog) {
    if (e.id == id) {
      return true;
    }
  }
  return false;
}

PlanItem _it(String id, int sets, int reps, int rest, [bool superset = false]) {
  return PlanItem(exerciseId: id, sets: sets, reps: reps, restSec: rest, supersetWithNext: superset);
}

/// Ready-made plans per style. They work without the AI coach.
const List<String> templateStyles = <String>[
  'Ganzkörper',
  'Push / Pull / Beine',
  'CrossFit',
  'Supersets',
  'Gerätetraining',
  'Calisthenics',
  'Kraft & Power',
];

List<Plan> templatePlans(String style, String Function() newId) {
  int n = 0;
  Plan p(String name, List<PlanItem> items) {
    n++;
    return Plan(id: '${newId()}_$n', name: name, items: items);
  }

  switch (style) {
    case 'Push / Pull / Beine':
      return <Plan>[
        p('Push', <PlanItem>[_it('bench', 4, 8, 90), _it('ohp', 3, 10, 90), _it('inclinedb', 3, 10, 60), _it('lateral', 3, 15, 45), _it('pushdown', 3, 12, 45)]),
        p('Pull', <PlanItem>[_it('deadlift', 3, 5, 120), _it('pullup', 3, 8, 90), _it('row', 3, 10, 60), _it('facepull', 3, 15, 45), _it('curl', 3, 12, 45)]),
        p('Beine', <PlanItem>[_it('squat', 4, 8, 120), _it('rdl', 3, 10, 90), _it('legpress', 3, 12, 60), _it('legcurl', 3, 12, 45), _it('calf', 3, 15, 30)]),
      ];
    case 'CrossFit':
      return <Plan>[
        p('CrossFit Zirkel', <PlanItem>[_it('burpee', 4, 10, 0, true), _it('swing', 4, 15, 0, true), _it('boxjump', 4, 10, 0, true), _it('wallball', 4, 15, 0, true), _it('rowerg', 4, 60, 90)]),
      ];
    case 'Supersets':
      return <Plan>[
        p('Supersets Ganzkörper', <PlanItem>[_it('bench', 3, 10, 0, true), _it('row', 3, 10, 90), _it('ohp', 3, 10, 0, true), _it('latpull', 3, 10, 90), _it('legext', 3, 12, 0, true), _it('legcurl', 3, 12, 90), _it('curl', 3, 12, 0, true), _it('pushdown', 3, 12, 60)]),
      ];
    case 'Gerätetraining':
      return <Plan>[
        p('Gerätetraining', <PlanItem>[_it('legpress', 3, 12, 90), _it('chestpress', 3, 10, 90), _it('latpull', 3, 10, 90), _it('shoulderpress', 3, 10, 60), _it('seatedrow', 3, 12, 60), _it('legcurl', 3, 12, 60), _it('pushdown', 3, 12, 45)]),
      ];
    case 'Calisthenics':
      return <Plan>[
        p('Calisthenics', <PlanItem>[_it('pushup', 3, 12, 60), _it('lunge', 3, 12, 60), _it('pullup', 3, 6, 90), _it('dips', 3, 8, 60), _it('legraise', 3, 12, 45), _it('plank', 3, 45, 30)]),
      ];
    case 'Kraft & Power':
      return <Plan>[
        p('Kraft & Power', <PlanItem>[_it('squat', 5, 5, 180), _it('bench', 5, 5, 180), _it('deadlift', 3, 5, 180), _it('ohp', 4, 6, 120)]),
      ];
    default:
      return <Plan>[
        p('Ganzkörper', <PlanItem>[_it('squat', 3, 10, 90), _it('bench', 3, 8, 90), _it('row', 3, 10, 60), _it('ohp', 3, 10, 60), _it('plank', 3, 45, 30)]),
      ];
  }
}

Exercise exerciseById(String id) {
  for (final Exercise e in exerciseCatalog) {
    if (e.id == id) {
      return e;
    }
  }
  return exerciseCatalog.first;
}

const List<String> stretchGroups = <String>['Nacken', 'Schultern', 'Brust', 'Rücken', 'Hüfte', 'Beine', 'Handgelenke'];

const List<Stretch> stretchCatalog = <Stretch>[
  Stretch(
    id: 'neck_side',
    name: 'Nacken seitlich',
    group: 'Nacken',
    muscles: <Muscle>[Muscle.neck, Muscle.shoulders],
    seconds: 60,
    steps: <String>['Kopf zur Schulter neigen', 'Gegenarm zieht sanft nach unten', '30 s halten, dann Seite wechseln'],
  ),
  Stretch(
    id: 'neck_turn',
    name: 'Kopf drehen',
    group: 'Nacken',
    muscles: <Muscle>[Muscle.neck],
    seconds: 40,
    steps: <String>['Aufrecht sitzen', 'Kopf langsam nach rechts drehen und 20 s halten', 'Dann nach links'],
  ),
  Stretch(
    id: 'shoulder_cross',
    name: 'Arm vor die Brust',
    group: 'Schultern',
    muscles: <Muscle>[Muscle.shoulders, Muscle.arms],
    seconds: 60,
    steps: <String>['Arm gestreckt vor die Brust führen', 'Mit der anderen Hand heranziehen', '30 s pro Seite'],
  ),
  Stretch(
    id: 'shoulder_roll',
    name: 'Schulterkreisen',
    group: 'Schultern',
    muscles: <Muscle>[Muscle.shoulders],
    seconds: 40,
    steps: <String>['Schultern zu den Ohren ziehen', 'Groß nach hinten kreisen', '10 Kreise, dann nach vorne'],
  ),
  Stretch(
    id: 'chest_door',
    name: 'Brustöffner am Türrahmen',
    group: 'Brust',
    muscles: <Muscle>[Muscle.chest, Muscle.shoulders],
    seconds: 60,
    steps: <String>['Unterarm an den Türrahmen legen', 'Oberkörper leicht nach vorne drehen', '30 s pro Seite'],
  ),
  Stretch(
    id: 'chest_clasp',
    name: 'Hände hinter dem Rücken',
    group: 'Brust',
    muscles: <Muscle>[Muscle.chest],
    seconds: 30,
    steps: <String>['Hände hinter dem Rücken verschränken', 'Schulterblätter zusammenziehen', 'Brust heben und 30 s halten'],
  ),
  Stretch(
    id: 'back_cat',
    name: 'Katzenbuckel im Sitzen',
    group: 'Rücken',
    muscles: <Muscle>[Muscle.core],
    seconds: 40,
    steps: <String>['Hände auf die Knie legen', 'Rücken rund machen, dann aufrichten', 'Langsam 8 Wiederholungen'],
  ),
  Stretch(
    id: 'back_twist',
    name: 'Drehsitz auf dem Stuhl',
    group: 'Rücken',
    muscles: <Muscle>[Muscle.core],
    seconds: 60,
    steps: <String>['Aufrecht sitzen, Füße am Boden', 'Oberkörper zur Lehne drehen', '30 s pro Seite'],
  ),
  Stretch(
    id: 'hip_flexor',
    name: 'Hüftbeuger im Ausfallschritt',
    group: 'Hüfte',
    muscles: <Muscle>[Muscle.hips, Muscle.quads],
    seconds: 60,
    steps: <String>['Großer Schritt nach vorne', 'Hinteres Knie absenken, Becken nach vorne schieben', '30 s pro Seite'],
  ),
  Stretch(
    id: 'hip_four',
    name: 'Sitzende Vier',
    group: 'Hüfte',
    muscles: <Muscle>[Muscle.hips],
    seconds: 60,
    steps: <String>['Knöchel auf das andere Knie legen', 'Mit geradem Rücken nach vorne lehnen', '30 s pro Seite'],
  ),
  Stretch(
    id: 'leg_ham',
    name: 'Beinrückseite im Stand',
    group: 'Beine',
    muscles: <Muscle>[Muscle.quads, Muscle.calves],
    seconds: 60,
    steps: <String>['Ferse nach vorne aufstellen', 'Mit geradem Rücken nach vorne beugen', '30 s pro Seite'],
  ),
  Stretch(
    id: 'leg_calf',
    name: 'Wade an der Wand',
    group: 'Beine',
    muscles: <Muscle>[Muscle.calves],
    seconds: 60,
    steps: <String>['Hände an die Wand', 'Ein Bein nach hinten, Ferse in den Boden drücken', '30 s pro Seite'],
  ),
  Stretch(
    id: 'wrist_flex',
    name: 'Handgelenke dehnen',
    group: 'Handgelenke',
    muscles: <Muscle>[Muscle.arms],
    seconds: 40,
    steps: <String>['Arm strecken, Handfläche nach oben', 'Finger mit der anderen Hand nach unten ziehen', '20 s pro Seite'],
  ),
];

/// The random stretches of one day. Each stretch comes from another body area
/// as long as possible, so the day covers the whole body.
List<Stretch> stretchPlanFor(StretchSettings settings, DateTime day) {
  final Random rnd = Random(settings.seedFor(day));
  final List<String> groups = stretchCatalog.map((Stretch s) => s.group).toSet().toList()..shuffle(rnd);
  final Map<String, List<Stretch>> byGroup = <String, List<Stretch>>{};
  for (final String g in groups) {
    byGroup[g] = stretchCatalog.where((Stretch s) => s.group == g).toList()..shuffle(rnd);
  }
  final List<Stretch> out = <Stretch>[];
  int round = 0;
  while (out.length < settings.perDay && round < 20) {
    for (final String g in groups) {
      final List<Stretch> pool = byGroup[g]!;
      if (out.length < settings.perDay && pool.isNotEmpty) {
        out.add(pool[round % pool.length]);
      }
    }
    round++;
  }
  return out;
}

Stretch stretchById(String id) {
  for (final Stretch s in stretchCatalog) {
    if (s.id == id) {
      return s;
    }
  }
  return stretchCatalog.first;
}
