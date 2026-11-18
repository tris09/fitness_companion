import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import 'common.dart';

/// A list of numbers from [from] to [to] in steps. Used for the wheel picker.
List<int> numberRange(int from, int to, {int step = 1}) {
  final List<int> out = <int>[];
  for (int v = from; v <= to; v += step) {
    out.add(v);
  }
  return out;
}

/// Opens a drum picker at the bottom of the screen. Returns the chosen value,
/// or null when the user cancels. If [initial] is not in [values] it is added,
/// so an existing value is never lost.
Future<int?> showWheelPicker(
  BuildContext context, {
  required String title,
  required List<int> values,
  required int initial,
  required String Function(int value) label,
}) {
  final List<int> list = List<int>.from(values);
  if (!list.contains(initial)) {
    list.add(initial);
    list.sort();
  }
  final AppColors c = AppColors.of(context);
  return showModalBottomSheet<int>(
    context: context,
    backgroundColor: c.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    builder: (BuildContext _) => _WheelSheet(title: title, values: list, initial: initial, label: label),
  );
}

class _WheelSheet extends StatefulWidget {
  final String title;
  final List<int> values;
  final int initial;
  final String Function(int value) label;

  const _WheelSheet({required this.title, required this.values, required this.initial, required this.label});

  @override
  State<_WheelSheet> createState() => _WheelSheetState();
}

class _WheelSheetState extends State<_WheelSheet> {
  static const double _itemHeight = 52;

  late final FixedExtentScrollController _controller;
  late int _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.values.indexOf(widget.initial);
    _controller = FixedExtentScrollController(initialItem: _selected);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(widget.title.toUpperCase(), style: heading(context, 28)),
            const SizedBox(height: 12),
            SizedBox(
              height: _itemHeight * 3.4,
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  IgnorePointer(
                    child: Container(
                      height: _itemHeight,
                      decoration: BoxDecoration(
                        border: Border.symmetric(horizontal: BorderSide(color: c.accentText, width: 2)),
                      ),
                    ),
                  ),
                  ListWheelScrollView.useDelegate(
                    controller: _controller,
                    itemExtent: _itemHeight,
                    diameterRatio: 1.8,
                    perspective: 0.003,
                    physics: const FixedExtentScrollPhysics(),
                    onSelectedItemChanged: (int i) {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selected = i;
                      });
                    },
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: widget.values.length,
                      builder: (BuildContext ctx, int i) {
                        final bool on = i == _selected;
                        return Center(
                          child: AnimatedDefaultTextStyle(
                            duration: kFast,
                            style: heading(ctx, on ? 36 : 26, color: on ? c.text : c.text3),
                            child: Text(widget.label(widget.values[i]).toUpperCase()),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              label: 'Übernehmen',
              onPressed: () => Navigator.of(context).pop(widget.values[_selected]),
            ),
            const SizedBox(height: 8),
            SecondaryButton(label: 'Abbrechen', onPressed: () => Navigator.of(context).pop()),
          ],
        ),
      ),
    );
  }
}
