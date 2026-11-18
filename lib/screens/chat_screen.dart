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

  const ChatScreen({super.key, this.initialPrompt});

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

  static const List<String> _suggestions = <String>[
    'Erstelle mir ein Training für heute',
    'Plan für diese Woche',
    'Was soll ich nach meinen letzten Trainings trainieren?',
    'Einkaufsliste für diese Woche mit Angeboten',
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
      // Only the last messages are sent. The long-term memory is the workout list in the system text.
      List<ChatMessage> recent = state.chat.length > 12 ? state.chat.sublist(state.chat.length - 12) : state.chat;
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
        system: buildCoachSystem(state, offers: offers),
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
                  Text(d.name, style: bodyStyle(context, size: 14, weight: FontWeight.w700)),
                  for (final PlanItem i in d.items)
                    Text(
                      '${exerciseById(i.exerciseId).name} · ${i.sets}×${i.reps}${exerciseById(i.exerciseId).timed ? ' s' : ''}${i.supersetWithNext ? ' · Superset' : ''}',
                      style: bodyStyle(context, size: 13, color: c.text2),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 4),
          PrimaryButton(
            label: m.saved ? 'In deinen Plänen' : 'In meine Pläne übernehmen',
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

  Widget _bubble(AppState state, ChatMessage m) {
    final AppColors c = AppColors.of(context);
    final bool mine = m.role == 'user';
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.86),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: mine ? c.accent : c.surface,
          border: Border.all(color: mine ? c.accent : c.border),
          borderRadius: BorderRadius.circular(kRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(m.text, style: bodyStyle(context, size: 15, color: mine ? c.onAccent : c.text)),
            if (m.programJson.isNotEmpty) _programCard(state, m),
            if (m.listJson.isNotEmpty) _listCard(state, m),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppState state = AppScope.of(context);
    final AppColors c = AppColors.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            PageHeader(kicker: 'Dein Coach', title: 'Chat', showBack: true),
            Expanded(
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                children: <Widget>[
                  if (state.chat.isEmpty) ...<Widget>[
                    Text(
                      'Schreib dem Coach, was du brauchst. Er kennt dein Profil, deine Körperdaten und deine letzten Trainings.',
                      style: bodyStyle(context, size: 14, color: c.text2),
                    ),
                    const SizedBox(height: 14),
                    for (final String s in _suggestions)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          onTap: _busy ? null : () => _send(s),
                          child: ChipBox(text: s, height: 48, showCheck: false),
                        ),
                      ),
                  ],
                  for (final ChatMessage m in state.chat) _bubble(state, m),
                  Reveal(
                    show: _busy,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(_status, style: bodyStyle(context, size: 14, color: c.text2)),
                    ),
                  ),
                  Reveal(
                    show: _error != null,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(_error ?? '', style: bodyStyle(context, size: 14, weight: FontWeight.w600)),
                    ),
                  ),
                  if (state.chat.isNotEmpty)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: _busy ? null : state.clearChat,
                        child: Text('Chat leeren', style: bodyStyle(context, size: 13, color: c.text2)),
                      ),
                    ),
                  Text(
                    'Die Antworten stammen von einer AI und ersetzen keine ärztliche oder sportfachliche Beratung.',
                    style: bodyStyle(context, size: 12, color: c.text2),
                  ),
                ],
              ),
            ),
            if (state.chat.isNotEmpty)
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: <Widget>[
                    for (final String q in _quick)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          onTap: _busy ? null : () => _send(q),
                          // A bounded width is needed inside a horizontal list.
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 260),
                            child: ChipBox(text: q, height: 40, showCheck: false),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 12, 12),
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
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: _busy ? null : () => _send(_input.text),
                    icon: Icon(Icons.send, color: _busy ? c.text3 : c.accentText),
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
