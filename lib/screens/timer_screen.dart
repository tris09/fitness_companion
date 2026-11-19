import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../catalog.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../training_memory.dart';
import '../widgets/common.dart';
import '../widgets/wheel_picker.dart';
import 'success_screen.dart';

enum _Kind { warmup, work, rest, cooldown }

class _Step {
  final _Kind kind;

  /// Set for work and rest steps. For a rest it is the exercise that comes next.
  final Exercise? exercise;

  /// Set for warm-up and cool-down steps.
  final Stretch? stretch;
  final int set;
  final int sets;
  final int reps;

  /// 0 = the user ends the set with a tap (fixed reps), otherwise a countdown in seconds.
  final int seconds;

  /// True for a time-limited set: it counts down, but a tap ends it early.
  final bool limit;

  /// Position inside warm-up or cool-down, e.g. 1 of 2.
  final int part;
  final int parts;

  const _Step({
    required this.kind,
    this.exercise,
    this.stretch,
    this.set = 0,
    this.sets = 0,
    this.reps = 0,
    required this.seconds,
    this.limit = false,
    this.part = 0,
    this.parts = 0,
  });

  _Step withSeconds(int s) => _Step(
        kind: kind,
        exercise: exercise,
        stretch: stretch,
        set: set,
        sets: sets,
        reps: reps,
        seconds: s,
        limit: limit,
        part: part,
        parts: parts,
      );

  bool get isRest => kind == _Kind.rest;
  bool get isStretch => kind == _Kind.warmup || kind == _Kind.cooldown;
}

/// Runs a plan step by step. Everything with a time runs on its own:
/// rests, timed exercises, time-limited sets, warm-up and cool-down.
/// Only sets with fixed reps wait for a tap, because only the user knows when they are done.
class TimerScreen extends StatefulWidget {
  final Plan plan;

  const TimerScreen({super.key, required this.plan});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  List<_Step> _steps = <_Step>[];
  bool _built = false;
  int _index = 0;
  int _remaining = 0;
  bool _paused = false;
  DateTime? _endAt;
  Timer? _ticker;

  /// Start of the workout, for the real duration in the statistics.
  final DateTime _startedAt = DateTime.now();

  /// Weights entered during the workout (kg per exercise id). Handed to the
  /// success screen, which saves them together with the feeling.
  final Map<String, double> _kg = <String, double>{};

  /// Opens the weight wheel. A running countdown is paused first and stays
  /// paused afterwards, so no time is lost while typing; "Weiter" continues.
  Future<void> _enterWeight(Exercise ex) async {
    final _Step step = _steps[_index];
    if (step.seconds > 0 && !_paused) {
      _togglePause();
    }
    final AppState state = AppScope.of(context);
    final double start = _kg[ex.id] ?? state.suggestedWeight(ex.id) ?? 20;
    final int? v = await showWheelPicker(
      context,
      title: ex.name,
      values: numberRange(0, 600),
      initial: (start * 2).round().clamp(0, 600),
      label: (int x) => formatKg(x / 2),
    );
    if (v != null && mounted) {
      setState(() => _kg[ex.id] = v / 2);
    }
  }

  @override
  void initState() {
    super.initState();
    // Keep the screen on during the workout.
    WakelockPlus.enable().catchError((Object _) {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_built) {
      _built = true;
      _steps = _buildSteps(widget.plan, AppScope.of(context).warmup);
      if (_steps.isNotEmpty) {
        _enter(0);
      }
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    WakelockPlus.disable().catchError((Object _) {});
    super.dispose();
  }

  /// Two stretches from different body areas, chosen by chance.
  static List<Stretch> _pickStretches(Random rnd, Set<String> avoid) {
    final List<Stretch> pool = stretchCatalog.where((Stretch s) => !avoid.contains(s.id)).toList()..shuffle(rnd);
    final List<Stretch> out = <Stretch>[];
    for (final Stretch s in pool) {
      if (out.length == 2) {
        break;
      }
      if (out.every((Stretch o) => o.group != s.group)) {
        out.add(s);
      }
    }
    return out;
  }

  static List<_Step> _buildSteps(Plan plan, bool warmup) {
    final List<_Step> out = <_Step>[];
    final Random rnd = Random();
    List<Stretch> before = <Stretch>[];
    if (warmup && plan.items.isNotEmpty) {
      before = _pickStretches(rnd, <String>{});
      for (int i = 0; i < before.length; i++) {
        out.add(_Step(kind: _Kind.warmup, stretch: before[i], seconds: before[i].seconds, part: i + 1, parts: before.length));
      }
    }

    // Items linked as a superset form one group and are done back to back.
    final List<List<PlanItem>> groups = <List<PlanItem>>[];
    List<PlanItem> current = <PlanItem>[];
    for (final PlanItem it in plan.items) {
      current.add(it);
      if (!it.supersetWithNext) {
        groups.add(current);
        current = <PlanItem>[];
      }
    }
    if (current.isNotEmpty) {
      groups.add(current);
    }

    for (int g = 0; g < groups.length; g++) {
      final List<PlanItem> group = groups[g];
      int rounds = 0;
      for (final PlanItem it in group) {
        rounds = max(rounds, it.sets);
      }
      for (int r = 1; r <= rounds; r++) {
        for (final PlanItem it in group) {
          if (r > it.sets) {
            continue;
          }
          final Exercise ex = exerciseById(it.exerciseId);
          final bool limit = !ex.timed && it.workSec > 0;
          out.add(_Step(
            kind: _Kind.work,
            exercise: ex,
            set: r,
            sets: it.sets,
            reps: it.reps,
            seconds: ex.timed ? it.reps : (limit ? it.workSec : 0),
            limit: limit,
          ));
        }
        final bool veryLast = g == groups.length - 1 && r == rounds;
        if (!veryLast) {
          // A rest is always required between sets, at least 10 s.
          final int rest = max(10, group.last.restSec);
          final PlanItem nextItem = r < rounds ? group.first : groups[g + 1].first;
          out.add(_Step(kind: _Kind.rest, exercise: exerciseById(nextItem.exerciseId), set: r, sets: rounds, seconds: rest));
        }
      }
    }

    if (warmup && plan.items.isNotEmpty) {
      final List<Stretch> after = _pickStretches(rnd, before.map((Stretch s) => s.id).toSet());
      for (int i = 0; i < after.length; i++) {
        out.add(_Step(kind: _Kind.cooldown, stretch: after[i], seconds: after[i].seconds, part: i + 1, parts: after.length));
      }
    }
    return out;
  }

  void _enter(int index) {
    _ticker?.cancel();
    _ticker = null;
    _index = index;
    _paused = false;
    final _Step step = _steps[index];
    _remaining = step.seconds;
    if (step.seconds > 0) {
      _endAt = DateTime.now().add(Duration(seconds: step.seconds));
      _startTicker();
    } else {
      _endAt = null;
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (Timer _) {
      if (!mounted || _endAt == null) {
        return;
      }
      final int ms = _endAt!.difference(DateTime.now()).inMilliseconds;
      final int left = ms <= 0 ? 0 : (ms / 1000).ceil();
      if (left <= 0) {
        HapticFeedback.heavyImpact();
        SystemSound.play(SystemSoundType.alert);
        _next();
      } else if (left != _remaining) {
        // Short signal in the last 3 seconds, so the screen does not have to be watched.
        if (left <= 3) {
          HapticFeedback.mediumImpact();
          SystemSound.play(SystemSoundType.click);
        }
        setState(() {
          _remaining = left;
        });
      }
    });
  }

  void _next() {
    if (_index >= _steps.length - 1) {
      _ticker?.cancel();
      AppScope.of(context).logWorkout(widget.plan, minutes: DateTime.now().difference(_startedAt).inMinutes);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (BuildContext _) => SuccessScreen(plan: widget.plan, entered: Map<String, double>.of(_kg))),
      );
      return;
    }
    setState(() {
      _enter(_index + 1);
    });
  }

  /// Ends a time-limited set early. The time left is added to the next rest.
  void _finishEarly() {
    final int left = _remaining;
    final int nextIndex = _index + 1;
    if (left > 0 && nextIndex < _steps.length && _steps[nextIndex].isRest) {
      _steps[nextIndex] = _steps[nextIndex].withSeconds(_steps[nextIndex].seconds + left);
    }
    HapticFeedback.mediumImpact();
    _next();
  }

  void _prev() {
    if (_index == 0) {
      return;
    }
    setState(() {
      _enter(_index - 1);
    });
  }

  void _togglePause() {
    setState(() {
      if (_paused) {
        _paused = false;
        _endAt = DateTime.now().add(Duration(seconds: _remaining));
        _startTicker();
      } else {
        _paused = true;
        _ticker?.cancel();
        _ticker = null;
      }
    });
  }

  String _info(_Step step) {
    if (step.kind == _Kind.warmup) {
      return 'Aufwärmen ${step.part} von ${step.parts}';
    }
    if (step.kind == _Kind.cooldown) {
      return 'Cooldown ${step.part} von ${step.parts}';
    }
    if (step.isRest) {
      return 'Als Nächstes';
    }
    final Exercise ex = step.exercise!;
    if (ex.timed) {
      return 'Satz ${step.set} von ${step.sets} · ${step.reps} s halten';
    }
    if (step.limit) {
      return 'Satz ${step.set} von ${step.sets} · Ziel ${step.reps} Wdh';
    }
    return 'Satz ${step.set} von ${step.sets} · ${step.reps} Wdh';
  }

  String _bigLabel(_Step step) {
    if (step.isRest) {
      return _paused ? 'Pause angehalten' : 'Pause';
    }
    if (step.isStretch) {
      return 'Dehnen · halten';
    }
    if (step.exercise!.timed) {
      return 'Halten';
    }
    return step.limit ? 'So viele wie möglich' : 'Wiederholungen';
  }

  String _nextText(_Step? upcoming) {
    if (upcoming == null) {
      return 'Danach: fertig';
    }
    if (upcoming.isRest) {
      return 'Danach: Pause ${formatRest(upcoming.seconds)}';
    }
    if (upcoming.isStretch) {
      return 'Danach: ${upcoming.stretch!.name}';
    }
    return 'Danach automatisch: ${upcoming.exercise!.name}, Satz ${upcoming.set}';
  }

  /// The training screen is always dark (graphite, not pure black) and uses large type,
  /// so it stays readable from a distance, e.g. with the phone on the floor.
  @override
  Widget build(BuildContext context) {
    return Theme(
      data: buildTheme(Brightness.dark, colors: kTrainingColors),
      child: MediaQuery(
        // Keep the user's text size, but never smaller than normal here.
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(MediaQuery.textScalerOf(context).scale(1) < 1 ? 1 : MediaQuery.textScalerOf(context).scale(1)),
        ),
        child: Builder(builder: _buildInner),
      ),
    );
  }

  Widget _buildInner(BuildContext context) {
    final AppColors c = AppColors.of(context);
    final AppState state = AppScope.of(context);
    if (_steps.isEmpty) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const PageHeader(kicker: 'Training', title: 'Kein Inhalt', showBack: true),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text('Dieser Plan enthält noch keine Übungen.', style: bodyStyle(context, color: c.text2)),
              ),
            ],
          ),
        ),
      );
    }

    final _Step step = _steps[_index];
    final _Step? upcoming = _index < _steps.length - 1 ? _steps[_index + 1] : null;
    final bool countdown = step.seconds > 0;
    final double progress = (_index + 1) / _steps.length;

    // During a rest the card already shows the exercise that comes next.
    final String title = step.isStretch ? step.stretch!.name : step.exercise!.name;
    final String sub = step.isStretch ? step.stretch!.group : step.exercise!.muscleLabel;
    final Exercise? weighted = step.isStretch ? null : step.exercise;
    final bool hasWeight = weighted != null && usesWeight(weighted);
    final double? entered = hasWeight ? _kg[weighted!.id] : null;
    final double? kg = hasWeight ? (entered ?? state.suggestedWeight(weighted!.id)) : null;

    Widget primary;
    if (step.limit) {
      primary = PrimaryButton(label: 'Satz fertig', icon: Icons.check, height: 88, fontSize: 28, onPressed: _finishEarly);
    } else if (countdown) {
      primary = PrimaryButton(
        label: _paused ? 'Weiter' : 'Pausieren',
        icon: _paused ? Icons.play_arrow : Icons.pause,
        height: 88,
        fontSize: 28,
        onPressed: _togglePause,
      );
    } else {
      primary = PrimaryButton(label: 'Satz fertig', icon: Icons.check, height: 88, fontSize: 28, onPressed: _next);
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            PageHeader(kicker: '${widget.plan.name} · Schritt ${_index + 1} von ${_steps.length}', title: 'Training'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Semantics(
                label: 'Fortschritt',
                child: Container(
                  height: 6,
                  color: c.border,
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(widthFactor: progress, child: Container(color: c.accentText)),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          SectionLabel(_info(step)),
                          const SizedBox(height: 6),
                          Text(title.toUpperCase(), style: heading(context, 46)),
                          const SizedBox(height: 4),
                          Text(sub, style: bodyStyle(context, size: 16, weight: FontWeight.w600, color: c.text2)),
                          if (hasWeight) ...<Widget>[
                            const SizedBox(height: 8),
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        entered != null ? 'Eingetragen' : (kg != null ? 'Vorschlag' : 'Gewicht'),
                                        style: bodyStyle(context, size: 13, color: c.text3),
                                      ),
                                      Text(
                                        kg == null ? '–' : formatKg(kg).toUpperCase(),
                                        style: heading(context, 30, color: entered != null ? c.accentText : c.text),
                                      ),
                                    ],
                                  ),
                                ),
                                // Big target: also usable with sweaty hands between sets.
                                SecondaryButton(
                                  label: entered != null ? 'Ändern' : 'Gewicht',
                                  expand: false,
                                  height: 56,
                                  fontSize: 20,
                                  onPressed: () => _enterWeight(weighted!),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          SectionLabel(_bigLabel(step), color: c.accentText),
                          const SizedBox(height: 6),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              countdown ? formatClock(_remaining) : '${step.reps}×',
                              style: heading(context, 210, color: countdown ? c.text : c.accentText).copyWith(
                                fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(_nextText(upcoming), textAlign: TextAlign.center, style: bodyStyle(context, size: 17, weight: FontWeight.w600, color: c.text2)),
                          if (step.limit)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Früher fertig? Die restliche Zeit kommt zur Pause dazu.',
                                textAlign: TextAlign.center,
                                style: bodyStyle(context, size: 13, color: c.text3),
                              ),
                            ),
                        ],
                      ),
                    ),
                    primary,
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(child: SecondaryButton(label: 'Zurück', height: 64, onPressed: _index == 0 ? null : _prev)),
                        const SizedBox(width: 12),
                        Expanded(child: SecondaryButton(label: 'Überspringen', height: 64, onPressed: _next)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Training beenden', style: bodyStyle(context, size: 14, color: c.text2)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
