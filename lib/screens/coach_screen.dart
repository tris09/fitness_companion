import 'package:flutter/material.dart';

import '../catalog.dart';
import '../models.dart';
import '../services/coach_service.dart';
import '../services/secrets.dart';
import '../state.dart';
import '../theme.dart';
import '../tutorials.dart';
import '../widgets/common.dart';
import '../widgets/tutorial_dialog.dart';
import 'chat_screen.dart';
import 'wiki_screen.dart';

/// The personal coach. Sends one controlled request to Gemini with the
/// user's own API key and turns the JSON answer into training plans.
class CoachScreen extends StatefulWidget {
  final void Function(int index) onOpenTab;

  const CoachScreen({super.key, required this.onOpenTab});

  @override
  State<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends State<CoachScreen> {
  final TextEditingController _keyCtrl = TextEditingController();
  final TextEditingController _noteCtrl = TextEditingController();

  bool _keyLoaded = false;
  String? _apiKey;

  /// True while the set-up is shown. Null means: decide from the saved profile.
  bool? _editing;
  CoachProfile? _draft;

  bool _busy = false;
  String? _error;
  String? _keyError;
  CoachProgram? _program;
  bool _saved = false;

  static const List<String> _goals = <String>['Muskelaufbau', 'Fett verlieren', 'Fit bleiben', 'Kraft'];
  static const List<String> _levels = <String>['Anfänger', 'Etwas Erfahrung', 'Erfahren'];

  @override
  void initState() {
    super.initState();
    _loadKey();
  }

  @override
  void dispose() {
    _keyCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadKey() async {
    final String? key = await Secrets.readGeminiKey();
    if (!mounted) {
      return;
    }
    setState(() {
      _apiKey = key;
      _keyLoaded = true;
    });
  }

  Future<void> _saveKey() async {
    final String value = _keyCtrl.text.trim();
    if (value.length < 10) {
      setState(() {
        _keyError = 'Der Schlüssel ist zu kurz.';
      });
      return;
    }
    final bool ok = await Secrets.writeGeminiKey(value);
    if (!mounted) {
      return;
    }
    setState(() {
      if (ok) {
        _apiKey = value;
        _keyCtrl.clear();
        _keyError = null;
      } else {
        _keyError = 'Der Schlüssel konnte nicht gespeichert werden.';
      }
    });
  }

  /// Asks before the key is removed. Cancel is the main button, so a quick tap keeps the key.
  Future<void> _confirmRemoveKey() async {
    final AppColors c = AppColors.of(context);
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: c.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadius), side: BorderSide(color: c.border)),
          title: Text('SCHLÜSSEL ENTFERNEN?', style: heading(ctx, 28)),
          content: Text(
            'Ohne Schlüssel funktionieren Coach, Chat und Einkaufslisten nicht mehr. '
            'Du musst ihn danach neu aus Google AI Studio kopieren.',
            style: bodyStyle(ctx, size: 15, color: c.text2),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                PrimaryButton(label: 'Behalten', height: 52, onPressed: () => Navigator.of(ctx).pop(false)),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: Text('Ja, endgültig entfernen', style: bodyStyle(ctx, size: 14, weight: FontWeight.w600, color: c.text2)),
                ),
              ],
            ),
          ],
        );
      },
    );
    if (ok == true) {
      await _removeKey();
    }
  }

  Future<void> _removeKey() async {
    await Secrets.deleteGeminiKey();
    if (!mounted) {
      return;
    }
    setState(() {
      _apiKey = null;
    });
  }

  Future<void> _create() async {
    final AppState state = AppScope.of(context);
    final CoachProfile profile = state.coachProfile;
    final String? key = _apiKey;
    if (key == null) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
      _program = null;
      _saved = false;
    });
    try {
      final CoachProgram program = await state.coach.createProgram(
        apiKey: key,
        model: state.coachModel,
        request: CoachRequest(
          styles: profile.styles,
          goal: profile.goal,
          level: profile.level,
          daysPerWeek: profile.days,
          minutes: profile.minutes,
          note: profile.aiDecides
              ? 'Ziel, Stil und Umfang darfst du selbst passend wählen. ${_noteCtrl.text}'
              : _noteCtrl.text,
        ),
      );
      final String? used = state.coach.lastWorkingModel;
      if (used != null && used != state.coachModel) {
        state.setCoachModel(used);
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _program = program;
        _busy = false;
      });
    } on CoachException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = e.message;
        _busy = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Etwas ist schiefgelaufen. Versuch es noch einmal.';
        _busy = false;
      });
    }
  }

  /// [columns] is at most 2 for long labels. Short labels (numbers) use one even row.
  Widget _choice<T>(
    List<T> values,
    T selected,
    String Function(T v) label,
    void Function(T v) onSelect, {
    int columns = 2,
  }) {
    return EvenGrid(
      columns: columns,
      children: <Widget>[
        for (final T v in values)
          InkWell(
            onTap: () {
              setState(() {
                onSelect(v);
              });
            },
            child: ChipBox(text: label(v), selected: v == selected, height: 44),
          ),
      ],
    );
  }

  /// Link to the style guide. Set apart from the chips so it does not read as an option.
  Widget _wikiLink() {
    final AppColors c = AppColors.of(context);
    return InkWell(
      onTap: _openWiki,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: c.surface,
          border: Border(left: BorderSide(color: c.accentText, width: 3)),
        ),
        child: Row(
          children: <Widget>[
            Icon(Icons.menu_book_outlined, size: 22, color: c.accentText),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text('Trainingsstile erklärt', style: bodyStyle(context, size: 15, weight: FontWeight.w700)),
                  Text('Unsicher? Hier steht, was zu dir passt.', style: bodyStyle(context, size: 13, color: c.text2)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: c.text2),
          ],
        ),
      ),
    );
  }

  Widget _styleChoice(CoachProfile draft) {
    return EvenGrid(
      columns: 2,
      children: <Widget>[
        for (final String v in trainingStyles)
          InkWell(
            onTap: () {
              setState(() {
                if (draft.styles.contains(v)) {
                  if (draft.styles.length > 1) {
                    draft.styles.remove(v);
                  }
                } else {
                  draft.styles.add(v);
                }
              });
            },
            child: ChipBox(text: v, selected: draft.styles.contains(v), height: 44),
          ),
      ],
    );
  }

  void _openWiki() {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (BuildContext _) => const WikiScreen()));
  }

  InputDecoration _input(String label, {String? hint}) {
    return fieldDecoration(context, label, hint: hint);
  }

  Widget _keySection() {
    final AppColors c = AppColors.of(context);
    if (!_keyLoaded) {
      return const SizedBox(height: 8);
    }
    if (_apiKey != null) {
      return AppCard(
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const SectionLabel('Gemini API-Schlüssel'),
                  const SizedBox(height: 6),
                  Text('Gespeichert auf diesem Gerät', style: bodyStyle(context, size: 15, weight: FontWeight.w600)),
                ],
              ),
            ),
            // Small and muted on purpose: removing the key needs a second, confirmed step.
            IconButton(
              tooltip: 'Schlüssel entfernen',
              onPressed: _busy ? null : _confirmRemoveKey,
              icon: Icon(Icons.delete_outline, color: AppColors.of(context).text3),
            ),
          ],
        ),
      );
    }
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const SectionLabel('Gemini API-Schlüssel'),
          const SizedBox(height: 8),
          Text(
            'Der Coach nutzt deinen eigenen Schlüssel aus Google AI Studio. Er bleibt geschützt auf diesem Gerät und geht nur an Google.',
            style: bodyStyle(context, size: 14, color: c.text2),
          ),
          const SizedBox(height: 12),
          SecondaryButton(
            label: 'Anleitung: Schlüssel holen',
            height: 46,
            fontSize: 17,
            onPressed: () => showTutorial(context, geminiKeyTutorial),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _keyCtrl,
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
            style: bodyStyle(context, size: 16, weight: FontWeight.w500),
            cursorColor: c.accentText,
            decoration: _input('API-Schlüssel einfügen'),
          ),
          if (_keyError != null) ...<Widget>[
            const SizedBox(height: 8),
            ErrorNote(_keyError!),
          ],
          const SizedBox(height: 12),
          PrimaryButton(label: 'Schlüssel speichern', height: 52, onPressed: _saveKey),
        ],
      ),
    );
  }

  Widget _result(CoachProgram program) {
    final AppColors c = AppColors.of(context);
    final AppState state = AppScope.of(context);
    return AppCard(
      borderColor: c.accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SectionLabel('Vorschlag vom Coach', color: c.accentText),
          const SizedBox(height: 8),
          Text(program.name.toUpperCase(), style: heading(context, 32)),
          const SizedBox(height: 12),
          for (final CoachDay day in program.days) ...<Widget>[
            Text(day.name.toUpperCase(), style: heading(context, 22)),
            const SizedBox(height: 6),
            for (final PlanItem it in day.items)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${it.sets} × ${it.reps}${exerciseById(it.exerciseId).timed ? ' s' : ''}  ${exerciseById(it.exerciseId).name}'
                  '${it.supersetWithNext ? '  · Superset' : '  · Pause ${formatRest(it.restSec)}'}',
                  style: bodyStyle(context, size: 14, color: c.text2),
                ),
              ),
            const SizedBox(height: 12),
          ],
          if (_saved) ...<Widget>[
            Text('Als Pläne gespeichert.', style: bodyStyle(context, size: 15, weight: FontWeight.w600)),
            const SizedBox(height: 10),
            SecondaryButton(label: 'Zu den Plänen', onPressed: () => widget.onOpenTab(1)),
          ] else ...<Widget>[
            PrimaryButton(
              label: 'Als Pläne speichern',
              onPressed: () {
                state.saveProgram(program);
                setState(() {
                  _saved = true;
                });
              },
            ),
            const SizedBox(height: 10),
            SecondaryButton(
              label: 'Verwerfen',
              onPressed: () {
                setState(() {
                  _program = null;
                });
              },
            ),
          ],
        ],
      ),
    );
  }

  /// The questions. Shown once at the start and again only on request.
  Widget _setup(AppState state, CoachProfile draft) {
    final AppColors c = AppColors.of(context);
    return Column(
      key: const ValueKey<String>('setup'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          state.coachProfile.done
              ? 'Ändere hier deine Ziele. Der Coach nutzt sie ab dem nächsten Programm.'
              : 'Das fragt dich der Coach nur einmal. Später kannst du es jederzeit ändern.',
          style: bodyStyle(context, size: 14, color: c.text2),
        ),
        const SizedBox(height: 18),
        const SectionLabel('Trainingsvorlieben'),
        const SizedBox(height: 8),
        _choice<bool>(const <bool>[true, false], draft.aiDecides, (bool v) => v ? 'Coach entscheidet' : 'Selbst wählen',
            (bool v) => draft.aiDecides = v),
        AnimatedSize(
          duration: kFast,
          curve: kEase,
          alignment: Alignment.topCenter,
          child: draft.aiDecides
              ? Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    'Der Coach wählt Ziel, Stil und Umfang passend zu deinen Körperdaten und Trainings.',
                    style: bodyStyle(context, size: 14, color: AppColors.of(context).text2),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const SizedBox(height: 18),
                    const SectionLabel('Trainingsstile · Mehrfachauswahl'),
                    const SizedBox(height: 8),
                    _styleChoice(draft),
                    const SizedBox(height: 12),
                    _wikiLink(),
                    const SizedBox(height: 22),
                    const SectionLabel('Ziel'),
                    const SizedBox(height: 8),
                    _choice<String>(_goals, draft.goal, (String v) => v, (String v) => draft.goal = v),
                    const SizedBox(height: 18),
                    const SectionLabel('Erfahrung'),
                    const SizedBox(height: 8),
                    _choice<String>(_levels, draft.level, (String v) => v, (String v) => draft.level = v),
                    const SizedBox(height: 18),
                    const SectionLabel('Trainingstage pro Woche'),
                    const SizedBox(height: 8),
                    _choice<int>(const <int>[2, 3, 4, 5, 6], draft.days, (int v) => '$v×', (int v) => draft.days = v, columns: 5),
                    const SizedBox(height: 18),
                    const SectionLabel('Dauer pro Einheit'),
                    const SizedBox(height: 8),
                    _choice<int>(const <int>[30, 45, 60, 90], draft.minutes, (int v) => '$v min', (int v) => draft.minutes = v, columns: 4),
                  ],
                ),
        ),
        const SizedBox(height: 22),
        PrimaryButton(
          label: 'Speichern',
          onPressed: () {
            state.saveCoachProfile(draft);
            setState(() {
              _editing = false;
              _draft = null;
            });
          },
        ),
        if (state.coachProfile.done) ...<Widget>[
          const SizedBox(height: 10),
          SecondaryButton(
            label: 'Abbrechen',
            onPressed: () {
              setState(() {
                _editing = false;
                _draft = null;
              });
            },
          ),
        ],
      ],
    );
  }

  Widget _profileLine(String label, String value) {
    final AppColors c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(width: 92, child: Padding(padding: const EdgeInsets.only(top: 2), child: SectionLabel(label))),
          Expanded(child: Text(value, style: bodyStyle(context, size: 15, weight: FontWeight.w600, color: c.text))),
        ],
      ),
    );
  }

  /// The normal view after the set-up: the saved profile and the create button.
  Widget _overview(AppState state, bool hasKey) {
    final AppColors c = AppColors.of(context);
    final CoachProfile p = state.coachProfile;
    final CoachProgram? program = _program;
    return Column(
      key: const ValueKey<String>('overview'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SectionLabel('Dein Coach-Profil'),
              const SizedBox(height: 12),
              if (p.aiDecides)
                _profileLine('Vorlieben', 'Coach entscheidet')
              else ...<Widget>[
                _profileLine('Stile', p.styles.join(', ')),
                _profileLine('Ziel', p.goal),
                _profileLine('Erfahrung', p.level),
                _profileLine('Training', '${p.days}× pro Woche · ${p.minutes} min'),
              ],
              _profileLine('Körper', '${state.body.weightKg.round()} kg · ${state.body.heightCm} cm · ${state.body.age} J.'),
              const SizedBox(height: 4),
              SecondaryButton(
                label: 'Ziele ändern',
                height: 46,
                fontSize: 17,
                onPressed: _busy
                    ? null
                    : () {
                        setState(() {
                          _draft = p.copy();
                          _editing = true;
                        });
                      },
              ),
              const SizedBox(height: 8),
              SecondaryButton(label: 'Trainingsstile erklärt', height: 46, fontSize: 17, onPressed: _openWiki),
            ],
          ),
        ),
        const SizedBox(height: 18),
        PrimaryButton(
          label: 'Mit dem Coach chatten',
          height: 64,
          fontSize: 22,
          icon: Icons.chat_bubble_outline,
          onPressed: hasKey
              ? () {
                  Navigator.of(context).push(MaterialPageRoute<void>(builder: (BuildContext _) => const ChatScreen()));
                }
              : null,
        ),
        const SizedBox(height: 6),
        Text(
          'Frag zum Beispiel: „Erstelle mir ein Training für heute.“ Der Coach kennt deine letzten Trainings.',
          style: bodyStyle(context, size: 13, color: c.text2),
        ),
        if (state.memory.isNotEmpty) ...<Widget>[
          const SizedBox(height: 18),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SectionLabel('Das merkt sich der Coach'),
                const SizedBox(height: 6),
                for (final String f in state.memory)
                  Row(
                    children: <Widget>[
                      Expanded(child: Text(f, style: bodyStyle(context, size: 14))),
                      IconButton(
                        tooltip: 'Vergessen',
                        onPressed: () => state.removeMemory(f),
                        icon: Icon(Icons.close, size: 18, color: c.text2),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 22),
        const SectionLabel('Oder: ganzes Wochenprogramm'),
        const SizedBox(height: 8),
        TextField(
          controller: _noteCtrl,
          enabled: !_busy,
          maxLines: 2,
          maxLength: 200,
          style: bodyStyle(context, size: 15),
          cursorColor: c.accentText,
          decoration: _input('Hinweis für den Coach (optional)', hint: 'z. B. kein Klimmzug möglich'),
        ),
        const SizedBox(height: 8),
        Reveal(
          show: _error != null,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ErrorNote(_error ?? ''),
          ),
        ),
        PrimaryButton(
          label: _busy ? 'Coach arbeitet …' : 'Wochenprogramm erstellen',
          height: 52,
          fontSize: 19,
          onPressed: (_busy || !hasKey) ? null : _create,
        ),
        if (!hasKey && _keyLoaded)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: const ErrorNote('Speichere zuerst deinen API-Schlüssel.', icon: Icons.key_outlined),
          ),
        const SizedBox(height: 8),
        Text(
          'Die Pläne stammen von einer AI und ersetzen keine ärztliche oder sportfachliche Beratung.',
          style: bodyStyle(context, size: 12, color: c.text2),
        ),
        Reveal(
          show: program != null,
          child: program == null
              ? const SizedBox.shrink()
              : Padding(padding: const EdgeInsets.only(top: 20), child: _result(program)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppState state = AppScope.of(context);
    final bool hasKey = _apiKey != null;
    final bool editing = _editing ?? !state.coachProfile.done;
    if (editing && _draft == null) {
      _draft = state.coachProfile.copy();
    }

    return ListView(
      padding: EdgeInsets.zero,
      children: <Widget>[
        const PageHeader(kicker: 'Dein persönlicher Coach', title: 'Coach', band: true),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _keySection(),
              const SizedBox(height: 20),
              AnimatedSize(
                duration: kFast,
                curve: kEase,
                alignment: Alignment.topCenter,
                child: AnimatedSwitcher(
                  duration: kFast,
                  switchInCurve: kEase,
                  transitionBuilder: (Widget w, Animation<double> a) => FadeTransition(opacity: a, child: w),
                  child: editing ? _setup(state, _draft!) : _overview(state, hasKey),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
