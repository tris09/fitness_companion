import 'package:flutter/material.dart';

import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/home_blocks.dart';

const Map<String, String> kBlockNames = <String, String>{
  'calendar': 'Kalender + Tagesplan',
  'ad': 'Anzeige',
  'tiles': 'Kacheln',
};

/// Move the blocks of Home with drag and drop. While dragging, a dashed area
/// shows where the block lands. The ad stays on Home; the news stay at the bottom.
class HomeEditScreen extends StatefulWidget {
  const HomeEditScreen({super.key});

  @override
  State<HomeEditScreen> createState() => _HomeEditScreenState();
}

class _HomeEditScreenState extends State<HomeEditScreen> {
  late List<String> _order;
  bool _init = false;
  String? _dragging;

  void _drop(String block, int slot) {
    setState(() {
      final int from = _order.indexOf(block);
      _order.removeAt(from);
      _order.insert(slot > from ? slot - 1 : slot, block);
      _dragging = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    final AppState state = AppScope.of(context);
    if (!_init) {
      _order = List<String>.of(state.homeOrder);
      _init = true;
    }
    final List<Widget> list = <Widget>[];
    for (int i = 0; i <= _order.length; i++) {
      list.add(_DropSlot(
        active: _dragging != null && _order.indexOf(_dragging!) != i && _order.indexOf(_dragging!) + 1 != i,
        onAccept: (String b) => _drop(b, i),
      ));
      if (i < _order.length) {
        final String b = _order[i];
        final Widget card = _BlockCard(block: b, note: b == 'ad' ? 'bleibt immer sichtbar' : 'verschiebbar');
        list.add(LongPressDraggable<String>(
          data: b,
          delay: const Duration(milliseconds: 180),
          onDragStarted: () => setState(() => _dragging = b),
          onDragEnd: (DraggableDetails _) => setState(() => _dragging = null),
          feedback: SizedBox(
            width: MediaQuery.sizeOf(context).width - 40,
            child: Transform.rotate(
              angle: -0.025,
              child: Material(
                elevation: 12,
                color: Colors.transparent,
                child: _BlockCard(block: b, note: 'wird gezogen', lifted: true),
              ),
            ),
          ),
          childWhenDragging: Opacity(opacity: 0.3, child: card),
          child: card,
        ));
      }
    }
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const PageHeader(kicker: 'Bearbeiten', title: 'Home anpassen', showBack: true),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                children: <Widget>[
                  Text(
                    'Block gedrückt halten und ziehen. Die gestrichelte Fläche zeigt, wo er beim Loslassen landet.',
                    style: bodyStyle(context, size: 14, color: c.text2),
                  ),
                  const SizedBox(height: 8),
                  ...list,
                  const SizedBox(height: 4),
                  Opacity(opacity: 0.55, child: _BlockCard(block: 'news', note: 'fest unten', locked: true)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  PrimaryButton(
                    label: 'Fertig',
                    onPressed: () {
                      state.setHomeOrder(_order);
                      Navigator.of(context).pop();
                    },
                  ),
                  TextButton(
                    onPressed: () => setState(() => _order = List<String>.of(kHomeBlocks)),
                    child: Text('Auf Standard zurücksetzen', style: bodyStyle(context, size: 14, weight: FontWeight.w700)),
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

/// Space between blocks. Grows into a dashed drop area while a block hovers over it.
class _DropSlot extends StatelessWidget {
  final bool active;
  final ValueChanged<String> onAccept;

  const _DropSlot({required this.active, required this.onAccept});

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    return DragTarget<String>(
      onWillAcceptWithDetails: (DragTargetDetails<String> _) => active,
      onAcceptWithDetails: (DragTargetDetails<String> d) => onAccept(d.data),
      builder: (BuildContext context, List<String?> candidates, List<dynamic> _) {
        final bool hover = candidates.isNotEmpty;
        return AnimatedContainer(
          duration: kFast,
          curve: kEase,
          height: hover ? 64 : (active ? 20 : 10),
          margin: EdgeInsets.symmetric(vertical: hover ? 6 : 0),
          child: hover
              ? CustomPaint(
                  painter: DashedBorder(color: c.text, width: 2),
                  child: Container(
                    color: c.lime.withOpacity(0.18),
                    alignment: Alignment.center,
                    child: Text('HIER ABLEGEN', style: labelStyle(context, color: c.text)),
                  ),
                )
              : null,
        );
      },
    );
  }
}

class _BlockCard extends StatelessWidget {
  final String block;
  final String note;
  final bool lifted;
  final bool locked;

  const _BlockCard({required this.block, required this.note, this.lifted = false, this.locked = false});

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    final String name = block == 'news' ? 'News' : (kBlockNames[block] ?? block);
    Widget preview;
    switch (block) {
      case 'calendar':
        preview = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(children: <Widget>[for (int i = 0; i < 7; i++) Expanded(child: Container(height: 22, margin: const EdgeInsets.only(right: 3), color: i == 2 ? c.lime : c.surface2))]),
            const SizedBox(height: 6),
            Container(height: 34, color: c.lime),
          ],
        );
        break;
      case 'ad':
        preview = Container(height: 30, alignment: Alignment.centerLeft, child: Text('ANZEIGE · Partner-Empfehlung', style: labelStyle(context)));
        break;
      case 'tiles':
        preview = Row(children: <Widget>[for (int i = 0; i < 4; i++) Expanded(child: Container(height: 30, margin: const EdgeInsets.only(right: 4), color: c.surface2))]);
        break;
      default:
        preview = Text('Fest unten · nicht verschiebbar', style: bodyStyle(context, size: 12, color: c.text3));
    }
    return Container(
      decoration: BoxDecoration(
        color: c.bg,
        border: Border.all(color: lifted ? c.text : c.border, width: lifted ? 1.5 : c.borderWidth),
        borderRadius: BorderRadius.circular(kRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            color: c.surface2,
            child: Row(
              children: <Widget>[
                Icon(locked ? Icons.lock_outline : Icons.drag_indicator, size: 18, color: c.text2),
                const SizedBox(width: 8),
                Expanded(child: Text(name.toUpperCase(), style: labelStyle(context, color: c.text))),
                Text(note, style: bodyStyle(context, size: 11, color: c.text3)),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(10), child: preview),
        ],
      ),
    );
  }
}
