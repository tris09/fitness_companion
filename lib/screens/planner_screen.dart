import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../catalog.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/wheel_picker.dart';

/// Training builder with two modes:
/// 'drag' = exercise list and plan side by side, blocks are dragged in.
/// 'list' = the plan as one vertical list, edited with buttons.
class PlannerScreen extends StatefulWidget {
  final Plan? plan;

  const PlannerScreen({super.key, this.plan});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  late List<PlanItem> _items;
  late TextEditingController _name;
  String _category = 'Alle';

  static const List<int> _setOptions = <int>[1, 2, 3, 4, 5, 6, 8, 10];
  static const List<int> _repOptions = <int>[5, 6, 8, 10, 12, 15, 20, 25];
  static const List<int> _timeOptions = <int>[20, 30, 45, 60, 90, 120];
  static const List<int> _restOptions = <int>[30, 60, 90, 120];
  static const List<int> _limitOptions = <int>[0, 30, 45, 60, 90, 120];

  @override
  void initState() {
    super.initState();
    _items = widget.plan == null ? <PlanItem>[] : widget.plan!.items.map((PlanItem e) => e.copy()).toList();
    _name = TextEditingController(text: widget.plan?.name ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  // ---------- Changing the plan ----------

  PlanItem _newItem(String exerciseId) {
    final Exercise ex = exerciseById(exerciseId);
    return PlanItem(exerciseId: exerciseId, sets: 3, reps: ex.timed ? 45 : 10, restSec: 60);
  }

  void _normalize() {
    if (_items.isNotEmpty) {
      _items.last.supersetWithNext = false;
    }
  }

  void _insert(String exerciseId, int index) {
    setState(() {
      final int at = index < 0 ? 0 : (index > _items.length ? _items.length : index);
      _items.insert(at, _newItem(exerciseId));
      _normalize();
    });
  }

  void _move(int from, int to) {
    if (from < 0 || from >= _items.length || from == to) {
      return;
    }
    setState(() {
      final PlanItem it = _items.removeAt(from);
      int target = to;
      if (from < to) {
        target -= 1;
      }
      if (target < 0) {
        target = 0;
      }
      if (target > _items.length) {
        target = _items.length;
      }
      _items.insert(target, it);
      _normalize();
    });
  }

  void _remove(int index) {
    setState(() {
      _items.removeAt(index);
      _normalize();
    });
  }

  /// A String is an exercise from the library, an int is a plan block being moved.
  void _drop(Object data, int index) {
    if (data is String) {
      _insert(data, index);
    } else if (data is int) {
      _move(data, index);
    }
  }

  // ---------- Wheel pickers (long press on a value) ----------

  Future<void> _wheelSets(PlanItem item) async {
    final int? picked = await showWheelPicker(
      context,
      title: 'Sätze',
      values: numberRange(1, 20),
      initial: item.sets,
      label: (int v) => '$v',
    );
    if (picked != null && mounted) {
      setState(() {
        item.sets = picked;
      });
    }
  }

  Future<void> _wheelReps(PlanItem item, Exercise ex) async {
    final int? picked = await showWheelPicker(
      context,
      title: ex.timed ? 'Dauer' : 'Wiederholungen',
      values: ex.timed ? numberRange(5, 600, step: 5) : numberRange(1, 100),
      initial: item.reps,
      label: (int v) => ex.timed ? formatRest(v) : '$v',
    );
    if (picked != null && mounted) {
      setState(() {
        item.reps = picked;
      });
    }
  }

  Future<void> _wheelLimit(PlanItem item) async {
    final int? picked = await showWheelPicker(
      context,
      title: 'Zeitlimit pro Satz',
      values: numberRange(0, 300, step: 5),
      initial: item.workSec,
      label: (int v) => v == 0 ? 'Kein Zeitlimit' : 'Max ${formatRest(v)}',
    );
    if (picked != null && mounted) {
      setState(() {
        item.workSec = picked;
      });
    }
  }

  Future<void> _wheelRest(PlanItem item) async {
    final int? picked = await showWheelPicker(
      context,
      title: 'Pause',
      // Minimum rest is 10 s. No rest at all only works through a superset.
      values: numberRange(10, 600, step: 5),
      initial: item.restSec < 10 ? 10 : item.restSec,
      label: formatRest,
    );
    if (picked != null && mounted) {
      setState(() {
        item.restSec = picked;
      });
    }
  }

  void _save() {
    final AppState state = AppScope.of(context);
    final String name = _name.text.trim().isEmpty ? 'Mein Plan' : _name.text.trim();
    _normalize();
    state.savePlan(Plan(id: widget.plan?.id ?? state.newId(), name: name, items: _items));
    Navigator.of(context).pop();
  }

  List<Exercise> _filtered(String category) {
    if (category == 'Alle') {
      return exerciseCatalog;
    }
    return exerciseCatalog.where((Exercise e) => e.category == category).toList();
  }

  // ---------- Shared pieces ----------

  Widget _categoryBar(String selected, void Function(String value) onSelect) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: <Widget>[
          for (final String cat in exerciseCategories)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () => onSelect(cat),
                child: ChipBox(text: cat, selected: cat == selected, height: 44),
              ),
            ),
        ],
      ),
    );
  }

  /// A value chip. Tap = quick list, hold = wheel picker for any value.
  Widget _menuChip({
    required String text,
    required List<int> values,
    required String Function(int v) label,
    required void Function(int v) onSelected,
    required VoidCallback onWheel,
  }) {
    return Builder(
      builder: (BuildContext chipContext) {
        return InkWell(
          onTap: () => _quickMenu(chipContext, values, label, onSelected),
          onLongPress: () {
            HapticFeedback.mediumImpact();
            onWheel();
          },
          child: ChipBox(text: text, height: 40),
        );
      },
    );
  }

  Future<void> _quickMenu(
    BuildContext chipContext,
    List<int> values,
    String Function(int v) label,
    void Function(int v) onSelected,
  ) async {
    final RenderBox box = chipContext.findRenderObject()! as RenderBox;
    final RenderBox overlay = Navigator.of(context).overlay!.context.findRenderObject()! as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        box.localToGlobal(Offset.zero, ancestor: overlay),
        box.localToGlobal(box.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );
    final int? picked = await showMenu<int>(
      context: context,
      position: position,
      items: <PopupMenuEntry<int>>[
        for (final int v in values) PopupMenuItem<int>(value: v, child: Text(label(v))),
      ],
    );
    if (picked != null && mounted) {
      onSelected(picked);
    }
  }

  Widget _feedback(String text) {
    final AppColors c = AppColors.of(context);
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: c.surface2,
          border: Border.all(color: c.accent, width: 2),
          borderRadius: BorderRadius.circular(kRadius),
        ),
        child: Text(text.toUpperCase(), style: heading(context, 19)),
      ),
    );
  }

  /// Superset group of the item: letter (A, B, …), position and size. Null for a single exercise.
  ({String letter, int pos, int size})? _group(int index) {
    int letter = 0;
    int i = 0;
    while (i < _items.length) {
      int end = i;
      while (end < _items.length - 1 && _items[end].supersetWithNext) {
        end++;
      }
      final int size = end - i + 1;
      if (size > 1) {
        if (index >= i && index <= end) {
          return (letter: String.fromCharCode(65 + letter % 26), pos: index - i + 1, size: size);
        }
        letter++;
      }
      i = end + 1;
    }
    return null;
  }

  /// One block of the plan. In list mode it also has buttons to move it.
  Widget _itemCard(int index, {required bool listMode}) {
    final AppColors c = AppColors.of(context);
    final PlanItem item = _items[index];
    final Exercise ex = exerciseById(item.exerciseId);
    final bool isLast = index == _items.length - 1;
    final ({String letter, int pos, int size})? group = _group(index);
    final bool linked = group != null;

    final Widget card = AnimatedContainer(
      duration: kFast,
      curve: kEase,
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      decoration: BoxDecoration(
        color: linked ? c.surface2 : c.surface,
        border: linked
            ? Border(
                left: BorderSide(color: c.accent, width: 8),
                top: BorderSide(color: c.accent, width: 2),
                right: BorderSide(color: c.accent, width: 2),
                bottom: BorderSide(color: c.accent, width: 2),
              )
            : Border.all(color: c.border, width: 1),
      ),
      child: AnimatedSize(
        duration: kFast,
        curve: kEase,
        alignment: Alignment.topCenter,
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (group != null)
                      Row(
                        children: <Widget>[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            color: c.accent,
                            child: Text(
                              '${group.letter}${group.pos}',
                              style: labelStyle(context, color: c.onAccent),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Superset ${group.letter} · ${group.pos} von ${group.size} · ${ex.category}'.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: labelStyle(context, color: c.accentText),
                            ),
                          ),
                        ],
                      )
                    else
                      Text('${index + 1} · Einzelübung · ${ex.category}'.toUpperCase(), style: labelStyle(context)),
                    const SizedBox(height: 4),
                    Text(ex.name.toUpperCase(), style: heading(context, listMode ? 24 : 20)),
                  ],
                ),
              ),
              if (listMode)
                IconButton(
                  tooltip: 'Nach oben',
                  onPressed: index == 0 ? null : () => _move(index, index - 1),
                  icon: Icon(Icons.arrow_upward, color: index == 0 ? c.text3 : c.text2),
                ),
              if (listMode)
                IconButton(
                  tooltip: 'Nach unten',
                  onPressed: isLast ? null : () => _move(index, index + 2),
                  icon: Icon(Icons.arrow_downward, color: isLast ? c.text3 : c.text2),
                ),
              IconButton(
                tooltip: 'Übung entfernen',
                onPressed: () => _remove(index),
                icon: Icon(Icons.close, color: c.text2),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                _menuChip(
                  text: '${item.sets} Sätze',
                  values: _setOptions,
                  label: (int v) => '$v Sätze',
                  onSelected: (int v) {
                    setState(() {
                      item.sets = v;
                    });
                  },
                  onWheel: () => _wheelSets(item),
                ),
                _menuChip(
                  text: ex.timed ? formatRest(item.reps) : '${item.reps} Wdh',
                  values: ex.timed ? _timeOptions : _repOptions,
                  label: (int v) => ex.timed ? formatRest(v) : '$v Wdh',
                  onSelected: (int v) {
                    setState(() {
                      item.reps = v;
                    });
                  },
                  onWheel: () => _wheelReps(item, ex),
                ),
                // Time limit: "as many reps as you can, at most X s". Not for exercises held for time.
                if (!ex.timed)
                  _menuChip(
                    text: item.workSec == 0 ? 'Kein Zeitlimit' : 'Max ${formatRest(item.workSec)}',
                    values: _limitOptions,
                    label: (int v) => v == 0 ? 'Kein Zeitlimit' : 'Max ${formatRest(v)}',
                    onSelected: (int v) {
                      setState(() {
                        item.workSec = v;
                      });
                    },
                    onWheel: () => _wheelLimit(item),
                  ),
                // The pause chip stays in place for supersets, so the block keeps its layout.
                AnimatedSwitcher(
                  duration: kFast,
                  child: item.supersetWithNext
                      ? const ChipBox(key: ValueKey<String>('nopause'), text: 'Ohne Pause', height: 40, muted: true)
                      : KeyedSubtree(
                          key: const ValueKey<String>('pause'),
                          child: _menuChip(
                            text: 'Pause ${formatRest(item.restSec)}',
                            values: _restOptions,
                            label: formatRest,
                            onSelected: (int v) {
                              setState(() {
                                item.restSec = v;
                              });
                            },
                            onWheel: () => _wheelRest(item),
                          ),
                        ),
                ),
              ],
            ),
          ),
          if (!isLast)
            InkWell(
              onTap: () {
                setState(() {
                  item.supersetWithNext = !item.supersetWithNext;
                });
              },
              child: SizedBox(
                height: 44,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(Icons.link, size: 18, color: item.supersetWithNext ? c.accentText : c.text2),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        item.supersetWithNext ? 'SUPERSET · OHNE PAUSE' : 'ALS SUPERSET VERBINDEN',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: labelStyle(context, color: item.supersetWithNext ? c.accentText : c.text2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      ),
    );

    // A solid bar joins the blocks of a superset, so the group reads as one unit.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        card,
        if (item.supersetWithNext && !isLast)
          Row(
            children: <Widget>[
              Container(width: 8, height: 18, color: c.accent),
              const SizedBox(width: 10),
              Icon(Icons.south, size: 14, color: c.accentText),
              const SizedBox(width: 4),
              Text('DIREKT WEITER', style: labelStyle(context, color: c.accentText)),
            ],
          ),
      ],
    );
  }

  // ---------- Mode 1: drag and drop ----------

  Widget _libraryTile(Exercise ex) {
    final AppColors c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: LongPressDraggable<Object>(
        data: ex.id,
        delay: const Duration(milliseconds: 180),
        feedback: _feedback(ex.name),
        child: InkWell(
          onTap: () => _insert(ex.id, _items.length),
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: c.surface,
              border: Border.all(color: c.border),
              borderRadius: BorderRadius.circular(kRadius),
            ),
            child: Row(
              children: <Widget>[
                Icon(Icons.drag_indicator, size: 18, color: c.text3),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(ex.name, style: bodyStyle(context, size: 13, weight: FontWeight.w600)),
                      Text(ex.muscleLabel, style: bodyStyle(context, size: 11, color: c.text2)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// A plan block that opens a gap above itself while something is dragged over it.
  Widget _dragRow(int index) {
    final AppColors c = AppColors.of(context);
    final Exercise ex = exerciseById(_items[index].exerciseId);
    final Widget card = _itemCard(index, listMode: false);
    return AppearIn(
      key: ObjectKey(_items[index]),
      child: Padding(
      padding: EdgeInsets.only(bottom: _items[index].supersetWithNext ? 0 : 8),
      child: DragTarget<Object>(
        onWillAcceptWithDetails: (DragTargetDetails<Object> d) => !(d.data is int && d.data == index),
        onAcceptWithDetails: (DragTargetDetails<Object> d) => _drop(d.data, index),
        builder: (BuildContext _, List<Object?> candidate, List<dynamic> rejected) {
          final bool open = candidate.isNotEmpty;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                curve: Curves.easeOut,
                height: open ? 64 : 0,
                margin: EdgeInsets.only(bottom: open ? 8 : 0),
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  color: c.surface2,
                  border: Border.all(color: open ? c.accent : Colors.transparent, width: 2),
                  borderRadius: BorderRadius.circular(kRadius),
                ),
                child: open
                    ? Center(child: Text('HIER EINFÜGEN', style: labelStyle(context, color: c.accentText)))
                    : null,
              ),
              LongPressDraggable<Object>(
                data: index,
                delay: const Duration(milliseconds: 220),
                feedback: _feedback(ex.name),
                childWhenDragging: Opacity(opacity: 0.35, child: card),
                child: card,
              ),
            ],
          );
        },
      ),
      ),
    );
  }

  Widget _dragBody() {
    final AppColors c = AppColors.of(context);
    final List<Exercise> library = _filtered(_category);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _categoryBar(_category, (String v) {
            setState(() {
              _category = v;
            });
          }),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                SizedBox(
                  width: 138,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const SectionLabel('Übungen'),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView(
                          padding: EdgeInsets.zero,
                          children: <Widget>[for (final Exercise ex in library) _libraryTile(ex)],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const SectionLabel('Ablaufplan'),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView(
                          padding: EdgeInsets.zero,
                          children: <Widget>[
                            for (int i = 0; i < _items.length; i++) _dragRow(i),
                            DragTarget<Object>(
                              onWillAcceptWithDetails: (DragTargetDetails<Object> d) => true,
                              onAcceptWithDetails: (DragTargetDetails<Object> d) => _drop(d.data, _items.length),
                              builder: (BuildContext _, List<Object?> candidate, List<dynamic> rejected) {
                                final bool open = candidate.isNotEmpty;
                                return Container(
                                  height: _items.isEmpty ? 140 : 72,
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: open ? c.surface2 : Colors.transparent,
                                    border: Border.all(color: open ? c.accent : c.text3, width: open ? 2 : 1),
                                    borderRadius: BorderRadius.circular(kRadius),
                                  ),
                                  child: Text(
                                    _items.isEmpty
                                        ? 'Übung gedrückt halten und hierher ziehen. Oder einfach antippen.'
                                        : 'Hier ans Ende ziehen',
                                    textAlign: TextAlign.center,
                                    style: bodyStyle(context, size: 12, color: c.text2),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Mode 2: list editor with buttons ----------

  Future<void> _pickAndInsert(int index) async {
    final AppColors c = AppColors.of(context);
    String category = 'Alle';
    final String? id = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.bg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (BuildContext sheetContext) {
        final AppColors sc = AppColors.of(sheetContext);
        return StatefulBuilder(
          builder: (BuildContext _, void Function(void Function()) setSheet) {
            final List<Exercise> list = _filtered(category);
            return SafeArea(
              child: SizedBox(
                height: MediaQuery.of(sheetContext).size.height * 0.78,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(child: Text('ÜBUNG WÄHLEN', style: heading(sheetContext, 30))),
                          IconButton(
                            tooltip: 'Schließen',
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            icon: Icon(Icons.close, color: sc.text2),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _categoryBar(category, (String v) {
                        setSheet(() {
                          category = v;
                        });
                      }),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.only(bottom: 16),
                          children: <Widget>[
                            for (final Exercise ex in list)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: InkWell(
                                  onTap: () => Navigator.of(sheetContext).pop(ex.id),
                                  child: Container(
                                    constraints: const BoxConstraints(minHeight: 60),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: sc.surface,
                                      border: Border.all(color: sc.border),
                                      borderRadius: BorderRadius.circular(kRadius),
                                    ),
                                    child: Row(
                                      children: <Widget>[
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: <Widget>[
                                              Text(ex.name.toUpperCase(), style: heading(sheetContext, 22)),
                                              const SizedBox(height: 2),
                                              Text(
                                                ex.muscleLabel,
                                                style: bodyStyle(sheetContext, size: 13, color: sc.text2),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Icon(Icons.add, color: sc.accentText),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    if (id != null && mounted) {
      _insert(id, index);
    }
  }

  Widget _insertButton(int index) {
    final AppColors c = AppColors.of(context);
    return InkWell(
      onTap: () => _pickAndInsert(index),
      child: SizedBox(
        height: 44,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.add, size: 18, color: c.text2),
            const SizedBox(width: 6),
            Text('HIER EINFÜGEN', style: labelStyle(context, color: c.text2)),
          ],
        ),
      ),
    );
  }

  Widget _listBody() {
    final AppColors c = AppColors.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: <Widget>[
        if (_items.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            child: Text(
              'Dein Plan ist noch leer. Füge die erste Übung hinzu.',
              style: bodyStyle(context, size: 15, color: c.text2),
            ),
          ),
        for (int i = 0; i < _items.length; i++) ...<Widget>[
          if (i > 0 && !_items[i - 1].supersetWithNext) _insertButton(i),
          AppearIn(key: ObjectKey(_items[i]), child: _itemCard(i, listMode: true)),
        ],
        const SizedBox(height: 16),
        PrimaryButton(
          label: 'Übung hinzufügen',
          icon: Icons.add,
          onPressed: () => _pickAndInsert(_items.length),
        ),
      ],
    );
  }

  // ---------- Screen ----------

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    final AppState state = AppScope.of(context);
    final bool dragMode = state.plannerMode == 'drag';

    Widget modeButton(String label, String mode) {
      return Expanded(
        child: InkWell(
          onTap: () => state.setPlannerMode(mode),
          child: ChipBox(text: label, selected: state.plannerMode == mode, height: 44),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            PageHeader(
              kicker: widget.plan == null ? 'Neuer Trainingsplan' : 'Plan bearbeiten',
              title: 'Trainingsplaner',
              showBack: true,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: <Widget>[
                  modeButton('Ziehen', 'drag'),
                  const SizedBox(width: 8),
                  modeButton('Liste', 'list'),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Text(
                'Tipp: Sätze, Wiederholungen oder Pause gedrückt halten für den Drehwähler.',
                style: bodyStyle(context, size: 12, color: c.text2),
              ),
            ),
            Expanded(child: dragMode ? _dragBody() : _listBody()),
            Container(
              decoration: BoxDecoration(border: Border(top: BorderSide(color: c.border))),
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _name,
                      style: bodyStyle(context, size: 16, weight: FontWeight.w500),
                      cursorColor: c.accentText,
                      decoration: InputDecoration(
                        labelText: 'Name des Plans',
                        labelStyle: bodyStyle(context, size: 13, color: c.text2),
                        isDense: true,
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: c.border)),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: c.accentText, width: 2)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  PrimaryButton(label: 'Speichern', height: 48, expand: false, onPressed: _items.isEmpty ? null : _save),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
