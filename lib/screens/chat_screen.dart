import 'dart:convert';

import 'package:flutter/material.dart';

import '../models.dart';
import '../services/coach_context.dart';
import '../services/coach_service.dart';
import '../services/secrets.dart';
import '../catalog.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Chat with the coach. The coach knows the profile, the body data and the
/// last workouts, and can create plans that are added to the plan list.
class ChatScreen extends StatefulWidget {
  /// Sent right away when the screen opens, e.g. from the quick button on Heute.
  final String? initialPrompt;

  /// True inside the Coach tab: title bar with the settings button, no back button.
  final bool embedded;

  /// Opens the coach settings (tab only).
  final VoidCallback? onOpenSettings;

  const ChatScreen({super.key, this.initialPrompt, this.embedded = false, this.onOpenSettings});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();

  bool _busy = false;
  String? _error;
  String _status = 'Coach schreibt …';

  @override
  void initState() {
    super.initState();
    final String? first = widget.initialPrompt;
    if (first != null && first.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((Duration _) => _send(first));
    }
  }

  /// True when the message is about food or shopping, so local offers are looked up first.
  static bool _wantsOffers(String text) {
    final String t = text.toLowerCase();
    return t.contains('einkauf') || t.contains('angebot') || t.contains('rezept') || t.contains('essen') || t.contains('mahlzeit');
  }

  /// Ready-made options above the input: (label, icon, message sent).
  static const List<(String, IconData, String)> _options = <(String, IconData, String)>[
    ('Plan für heute', Icons.bolt, 'Erstelle mir ein Training für heute'),
    ('Woche planen', Icons.calendar_month_outlined, 'Plane meine Trainingstage für diese Woche'),
    ('Einkaufsliste', Icons.shopping_cart_outlined, 'Einkaufsliste für diese Woche mit Angeboten'),
    ('Meine Ziele', Icons.flag_outlined, 'Passen meine Ziele und mein Trainingsumfang noch zu meinem Verlauf?'),
  ];

  /// Quick changes to the last answer, shown above the input once a chat runs.
  static const List<String> _quick = <String>[
    'Heute nur 20 Minuten',
    'Etwas zwickt, bitte schonender',
    'Ohne Geräte',
    'Mehr Pause',
  ];

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _toBottom() {
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent, duration: kFast, curve: kEase);
      }
    });
  }

  Future<void> _send(String raw) async {
    final String text = raw.trim();
    if (text.isEmpty || _busy) {
      return;
    }
    final AppState state = AppScope.of(context);
    final String? key = await Secrets.readGeminiKey();
    if (!mounted) {
      return;
    }
    if (key == null) {
      setState(() => _error = 'Speichere zuerst deinen API-Schlüssel im Coach-Tab.');
      return;
    }
    _input.clear();
    state.addChat(ChatMessage(role: 'user', text: text));
    setState(() {
      _busy = true;
      _error = null;
    });
    _toBottom();
    try {
      // Only the last 8 messages are sent. The long-term memory is a short summary in the system text.
      List<ChatMessage> recent = state.chat.length > 8 ? state.chat.sublist(state.chat.length - 8) : state.chat;
      while (recent.isNotEmpty && recent.first.role != 'user') {
        recent = recent.sublist(1);
      }
      OfferInfo? offers;
      if (_wantsOffers(text) && state.shop.place.trim().isNotEmpty) {
        setState(() => _status = 'Suche Angebote in ${state.shop.place.trim()} …');
        offers = await state.coach.findOffers(
          apiKey: key,
          model: state.coachModel,
          place: state.shop.place,
          stores: state.shop.stores,
        );
        if (mounted) {
          setState(() => _status = 'Coach schreibt …');
        }
      }
      final CoachReply reply = await state.coach.chat(
        apiKey: key,
        model: state.coachModel,
        system: buildCoachSystem(
          state,
          offers: offers,
          // Topic from the last user messages, so short follow-ups keep the right context.
          topic: guessTopic(recent.where((ChatMessage m) => m.role == 'user').map((ChatMessage m) => m.text).join(' ')),
        ),
        turns: recent.map((ChatMessage m) => ChatTurn(m.role, m.text)).toList(),
      );
      final String? used = state.coach.lastWorkingModel;
      if (used != null && used != state.coachModel) {
        state.setCoachModel(used);
      }
      if (reply.remember.isNotEmpty) {
        state.addMemory(reply.remember);
      }
      String answer = reply.text;
      if (reply.remember.isNotEmpty) {
        answer += '\n\nGemerkt: ${reply.remember.join('; ')}';
      }
      state.addChat(ChatMessage(
        role: 'model',
        text: answer,
        programJson: reply.program?.json ?? '',
        listJson: reply.listJson,
        settingsJson: reply.settingsJson,
        sources: reply.listJson.isEmpty ? <String>[] : (offers?.sources ?? <String>[]),
      ));
      if (mounted) {
        setState(() => _busy = false);
      }
    } on CoachException catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = e.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Etwas ist schiefgelaufen. Versuch es noch einmal.';
        });
      }
    }
    _toBottom();
  }

  static String _saveLabel(CoachProgram p) {
    if (p.templateDays == 0) {
      return 'In den Kalender eintragen';
    }
    return p.datedDays == 0 ? 'In meine Pläne übernehmen' : 'Übernehmen';
  }

  static String _savedLabel(CoachProgram p) {
    if (p.templateDays == 0) {
      return 'Im Kalender eingetragen';
    }
    return p.datedDays == 0 ? 'In deinen Plänen' : 'Übernommen';
  }

  static String _targetText(CoachProgram p) {
    final List<String> parts = <String>[
      if (p.datedDays > 0) '${p.datedDays} ${p.datedDays == 1 ? 'Tag kommt' : 'Tage kommen'} nur in den Kalender',
      if (p.templateDays > 0) '${p.templateDays} ${p.templateDays == 1 ? 'Plan wird Vorlage' : 'Pläne werden Vorlagen'} unter Pläne',
    ];
    return '${parts.join(', ')}.';
  }

  Widget _programCard(AppState state, ChatMessage m) {
    final AppColors c = AppColors.of(context);
    CoachProgram program;
    try {
      program = CoachProgram.parse(m.programJson);
    } catch (_) {
      return const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.surface2,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(kRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SectionLabel(program.name),
          const SizedBox(height: 8),
          for (final CoachDay d in program.days)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    d.date == null ? d.name : '${d.name} · ${weekdayShort[d.date!.weekday - 1]} ${d.date!.day}.${d.date!.month}.',
                    style: bodyStyle(context, size: 14, weight: FontWeight.w700),
                  ),
                  for (final PlanItem i in d.items)
                    Text(
                      '${exerciseById(i.exerciseId).name} · ${i.sets}×${i.reps}${exerciseById(i.exerciseId).timed ? ' s' : ''}${i.supersetWithNext ? ' · Superset' : ''}',
                      style: bodyStyle(context, size: 13, color: c.text2),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 4),
          // Dated days go to the calendar only, days without a date become templates.
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(_targetText(program), style: bodyStyle(context, size: 12, color: c.text3)),
          ),
          PrimaryButton(
            label: m.saved ? _savedLabel(program) : _saveLabel(program),
            height: 46,
            fontSize: 17,
            onPressed: m.saved
                ? null
                : () {
                    state.saveChatProgram(m);
                    setState(() {});
                  },
          ),
        ],
      ),
    );
  }

  Widget _listCard(AppState state, ChatMessage m) {
    final AppColors c = AppColors.of(context);
    ShoppingList list;
    try {
      list = ShoppingList.fromJson(Map<String, dynamic>.from(jsonDecode(m.listJson) as Map));
    } catch (_) {
      return const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.surface2,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(kRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SectionLabel(list.title),
          const SizedBox(height: 6),
          for (final ShoppingItem i in list.items.take(8))
            Text(
              '${i.amount.isEmpty ? '' : '${i.amount} '}${i.name}${i.offer.isEmpty ? '' : ' · ${i.offer}'}',
              style: bodyStyle(context, size: 13, color: c.text2),
            ),
          if (list.items.length > 8)
            Text('+ ${list.items.length - 8} weitere', style: bodyStyle(context, size: 13, color: c.text2)),
          if (m.sources.isNotEmpty) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              'Angebote laut: ${m.sources.map((String e) => e.split('|').first).join(', ')}',
              style: bodyStyle(context, size: 11, color: c.text3),
            ),
          ],
          const SizedBox(height: 10),
          PrimaryButton(
            label: m.listSaved ? 'Im Tab Essen' : 'Einkaufsliste übernehmen',
            height: 46,
            fontSize: 17,
            onPressed: m.listSaved
                ? null
                : () {
                    state.saveChatList(m);
                    setState(() {});
                  },
          ),
        ],
      ),
    );
  }

  /// Chat bubbles: own messages dark on the right (inverted colours), coach on the left.
  Widget _bubble(AppState state, ChatMessage m) {
    final AppColors c = AppColors.of(context);
    final bool mine = m.role == 'user';
    final Widget bubble = Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * (mine ? 0.78 : 0.8)),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: mine ? c.text : c.surface,
        border: Border.all(color: mine ? c.text : c.border, width: c.borderWidth),
        borderRadius: BorderRadius.circular(kRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(m.text, style: bodyStyle(context, size: 15, color: mine ? c.bg : c.text)),
          if (m.programJson.isNotEmpty) _programCard(state, m),
          if (m.listJson.isNotEmpty) _listCard(state, m),
          if (m.settingsJson.isNotEmpty) _settingsCard(state, m),
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: mine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          if (!mine) ...<Widget>[const _CoachAvatar(), const SizedBox(width: 8)],
          Flexible(child: bubble),
        ],
      ),
    );
  }

  /// Proposal of new coach settings. Nothing changes until the user taps "Übernehmen".
  Widget _settingsCard(AppState state, ChatMessage m) {
    final AppColors c = AppColors.of(context);
    Map<String, dynamic> j;
    try {
      j = Map<String, dynamic>.from(jsonDecode(m.settingsJson) as Map);
    } catch (_) {
      return const SizedBox.shrink();
    }
    final CoachProfile p = state.coachProfile;
    final List<(String, String, String)> rows = <(String, String, String)>[
      if (j['aiDecides'] is bool)
        ('Planung', p.aiDecides ? 'Coach entscheidet' : 'Selbst gewählt', j['aiDecides'] == true ? 'Coach entscheidet' : 'Selbst gewählt'),
      if (j['goal'] is String) ('Ziel', p.goal, j['goal'] as String),
      if (j['level'] is String) ('Erfahrung', p.level, j['level'] as String),
      if (j['days'] is num) ('Tage pro Woche', '${p.days}×', '${(j['days'] as num).toInt()}×'),
      if (j['minutes'] is num) ('Dauer', '${p.minutes} min', '${(j['minutes'] as num).toInt()} min'),
      if (j['styles'] is List) ('Stile', p.styles.join(', '), (j['styles'] as List<dynamic>).join(', ')),
    ];
    final String reason = '${j['reason'] ?? ''}';
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.bg,
        border: Border.all(color: c.text, width: 1.5),
        borderRadius: BorderRadius.circular(kRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const SectionLabel('Vorschlag: neue Einstellungen'),
          const SizedBox(height: 8),
          for (final (String label, String from, String to) in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(label, style: bodyStyle(context, size: 12, color: c.text3)),
                  Text('$from  →  $to', style: bodyStyle(context, size: 14, weight: FontWeight.w700)),
                ],
              ),
            ),
          if (reason.isNotEmpty) Text(reason, style: bodyStyle(context, size: 13, color: c.text2)),
          const SizedBox(height: 10),
          if (m.settingsState.isEmpty)
            Row(
              children: <Widget>[
                Expanded(
                  child: PrimaryButton(
                    label: 'Übernehmen',
                    height: 44,
                    fontSize: 16,
                    onPressed: () {
                      state.answerSettingsProposal(m, true);
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SecondaryButton(
                    label: 'Ablehnen',
                    height: 44,
                    fontSize: 16,
                    onPressed: () {
                      state.answerSettingsProposal(m, false);
                      setState(() {});
                    },
                  ),
                ),
              ],
            )
          else
            Text(
              m.settingsState == 'accepted' ? '✓ Übernommen' : 'Abgelehnt, nichts geändert',
              style: bodyStyle(context, size: 14, weight: FontWeight.w700),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppState state = AppScope.of(context);
    final AppColors c = AppColors.of(context);
    final Widget header = widget.embedded
        ? PageHeader(
            kicker: 'Dein persönlicher Coach',
            title: 'Coach',
            band: true,
            trailing: Builder(
              builder: (BuildContext ctx) => IconButton(
                tooltip: 'Coach-Einstellungen',
                onPressed: widget.onOpenSettings,
                icon: Icon(Icons.tune, color: AppColors.of(ctx).text),
              ),
            ),
          )
        : const PageHeader(kicker: 'Dein Coach', title: 'Chat', showBack: true);
    final Widget column = Column(
      children: <Widget>[
        header,
        Expanded(
          child: ListView(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
            children: <Widget>[
              if (state.chat.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      const _CoachAvatar(),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: c.surface,
                            border: Border.all(color: c.border, width: c.borderWidth),
                            borderRadius: BorderRadius.circular(kRadius),
                          ),
                          child: Text(
                            state.firstName.isEmpty
                                ? 'Hi! Ich kenne dein Profil, deine Körperdaten und deine letzten Trainings. Womit fangen wir an?'
                                : 'Hi ${state.firstName}! Ich kenne dein Profil, deine Körperdaten und deine letzten Trainings. Womit fangen wir an?',
                            style: bodyStyle(context, size: 15),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              for (final ChatMessage m in state.chat) _bubble(state, m),
              Reveal(
                show: _busy,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10, left: 40),
                  child: Text(_status, style: bodyStyle(context, size: 14, color: c.text2)),
                ),
              ),
              Reveal(
                show: _error != null,
                child: Padding(padding: const EdgeInsets.only(bottom: 10), child: ErrorNote(_error ?? '')),
              ),
              Text(
                'Die Antworten stammen von einer AI und ersetzen keine ärztliche oder sportfachliche Beratung.',
                style: bodyStyle(context, size: 11, color: c.text3),
              ),
            ],
          ),
        ),
        // Ready-made options, then quick changes to the last answer once a chat runs.
        SizedBox(
          height: 46,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
            children: <Widget>[
              for (final (String label, IconData icon, String msg) in _options)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _OptionChip(label: label, icon: icon, onTap: _busy ? null : () => _send(msg)),
                ),
              if (state.chat.isNotEmpty)
                for (final String q in _quick)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _OptionChip(label: q, onTap: _busy ? null : () => _send(q)),
                  ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
          decoration: BoxDecoration(color: c.bg, border: Border(top: BorderSide(color: c.border))),
          child: Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _input,
                  enabled: !_busy,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: _send,
                  style: bodyStyle(context, size: 15),
                  cursorColor: c.accentText,
                  decoration: fieldDecoration(context, 'Nachricht an den Coach'),
                ),
              ),
              const SizedBox(width: 8),
              Semantics(
                button: true,
                label: 'Senden',
                child: InkWell(
                  onTap: _busy ? null : () => _send(_input.text),
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: _busy ? c.surface2 : c.accent,
                      border: Border.all(color: c.accentEdge ?? c.accent, width: c.accentEdge == null ? 0 : 1.5),
                      borderRadius: BorderRadius.circular(kRadius),
                    ),
                    child: Icon(Icons.send, color: _busy ? c.text3 : c.onAccent),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
    if (widget.embedded) {
      return column;
    }
    return Scaffold(body: SafeArea(child: column));
  }
}

/// Round coach mark next to the coach's messages.
class _CoachAvatar extends StatelessWidget {
  const _CoachAvatar();

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.isDark ? c.surface2 : const Color(0xFF1E2124),
        shape: BoxShape.circle,
        border: c.highContrast ? Border.all(color: c.text, width: c.borderWidth) : null,
      ),
      child: Text('GC', style: heading(context, 15, color: c.lime)),
    );
  }
}

/// Chip with an optional icon for the options above the input.
class _OptionChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;

  const _OptionChip({required this.label, this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: c.control,
          border: Border.all(color: c.outline, width: c.borderWidth),
          borderRadius: BorderRadius.circular(kRadius),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (icon != null) ...<Widget>[Icon(icon, size: 16, color: c.text), const SizedBox(width: 6)],
            Text(label, style: bodyStyle(context, size: 13, weight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
