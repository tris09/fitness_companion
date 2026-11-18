import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../catalog.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'success_screen.dart';

class _Step {
  final bool rest;
  final Exercise exercise;
  final int set;
  final int sets;
  final int reps;

  /// 0 = the user confirms the step by hand, otherwise a countdown in seconds.
  final int seconds;

  _Step({
    required this.rest,
    required this.exercise,
    required this.set,
    required this.sets,
    required this.reps,
    required this.seconds,
  });
}

/// Runs a plan step by step. Rests and timed exercises count down on their own.
class TimerScreen extends StatefulWidget {
  final Plan plan;

  const TimerScreen({super.key, required this.plan});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  late List<_Step> _steps;
  int _index = 0;
  int _remaining = 0;
  bool _paused = false;
  DateTime? _endAt;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _steps = _buildSteps(widget.plan);
    _enter(0);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  static List<_Step> _buildSteps(Plan plan) {
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

    final List<_Step> out = <_Step>[];
    for (int g = 0; g < groups.length; g++) {
      final List<PlanItem> group = groups[g];
      int rounds = 0;
      for (final PlanItem it in group) {
        if (it.sets > rounds) {
          rounds = it.sets;
        }
      }
      for (int r = 1; r <= rounds; r++) {
        for (final PlanItem it in group) {
          if (r > it.sets) {
            continue;
          }
          final Exercise ex = exerciseById(it.exerciseId);
          out.add(_Step(rest: false, exercise: ex, set: r, sets: it.sets, reps: it.reps, seconds: ex.timed ? it.reps : 0));
        }
        final bool veryLast = g == groups.length - 1 && r == rounds;
        final int rest = group.last.restSec;
        if (!veryLast && rest > 0) {
          out.add(_Step(
            rest: true,
            exercise: exerciseById(group.last.exerciseId),
            set: r,
            sets: rounds,
            reps: 0,
            seconds: rest,
          ));
        }
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
        _next();
      } else if (left != _remaining) {
        setState(() {
          _remaining = left;
        });
      }
    });
  }

  void _next() {
    if (_index >= _steps.length - 1) {
      _ticker?.cancel();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (BuildContext _) => SuccessScreen(plan: widget.plan)),
      );
      return;
    }
    setState(() {
      _enter(_index + 1);
    });
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

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
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

    String info;
    if (step.rest) {
      info = 'Pause nach Satz ${step.set}';
    } else if (step.exercise.timed) {
      info = 'Satz ${step.set} von ${step.sets} · ${step.reps} s halten';
    } else {
      info = 'Satz ${step.set} von ${step.sets} · ${step.reps} Wdh';
    }

    String nextText;
    if (upcoming == null) {
      nextText = 'Danach: fertig';
    } else if (upcoming.rest) {
      nextText = 'Danach: Pause ${formatRest(upcoming.seconds)}';
    } else {
      nextText = 'Danach automatisch: ${upcoming.exercise.name}, Satz ${upcoming.set}';
    }

    final Exercise shown = step.rest && upcoming != null ? upcoming.exercise : step.exercise;

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
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                SectionLabel(step.rest ? 'Als Nächstes' : info),
                                const SizedBox(height: 6),
                                Text(shown.name.toUpperCase(), style: heading(context, 32)),
                                const SizedBox(height: 4),
                                Text(shown.muscleLabel, style: bodyStyle(context, size: 13, color: c.text2)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          SectionLabel(
                            countdown ? (step.rest ? (_paused ? 'Pause angehalten' : 'Pause') : 'Halten') : 'Wiederholungen',
                            color: c.accentText,
                          ),
                          const SizedBox(height: 6),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              countdown ? formatClock(_remaining) : '${step.reps}×',
                              style: heading(context, 140).copyWith(
                                fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(nextText, textAlign: TextAlign.center, style: bodyStyle(context, size: 14, color: c.text2)),
                        ],
                      ),
                    ),
                    PrimaryButton(
                      label: countdown ? (_paused ? 'Weiter' : 'Pausieren') : 'Satz fertig',
                      icon: countdown ? (_paused ? Icons.play_arrow : Icons.pause) : Icons.check,
                      height: 88,
                      fontSize: 28,
                      onPressed: countdown ? _togglePause : _next,
                    ),
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
