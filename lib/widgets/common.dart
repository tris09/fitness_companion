import 'package:flutter/material.dart';

import '../theme.dart';

class SectionLabel extends StatelessWidget {
  final String text;
  final Color? color;

  const SectionLabel(this.text, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Text(text.toUpperCase(), style: labelStyle(context, color: color));
  }
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final double height;
  final double fontSize;
  final IconData? icon;
  final bool expand;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.height = 56,
    this.fontSize = 19,
    this.icon,
    this.expand = true,
  });

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    final Color fg = onPressed == null ? c.text3 : c.onAccent;
    return SizedBox(
      height: height,
      width: expand ? double.infinity : null,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: c.accent,
          foregroundColor: c.onAccent,
          disabledBackgroundColor: c.surface2,
          disabledForegroundColor: c.text3,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadius)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (icon != null) Icon(icon, size: fontSize + 4, color: fg),
            if (icon != null) const SizedBox(width: 8),
            Flexible(
              child: Text(
                label.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: heading(context, fontSize, color: fg),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final double height;
  final double fontSize;
  final bool expand;

  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.height = 52,
    this.fontSize = 18,
    this.expand = true,
  });

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    return SizedBox(
      height: height,
      width: expand ? double.infinity : null,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: c.text,
          side: BorderSide(color: c.border),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadius)),
        ),
        child: Text(
          label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: heading(context, fontSize, color: onPressed == null ? c.text3 : c.text),
        ),
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;

  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.borderColor});

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: borderColor ?? c.border),
        borderRadius: BorderRadius.circular(kRadius),
      ),
      child: child,
    );
  }
}

/// Small bordered box used for options. Wrap it in an InkWell to make it tappable.
/// When selected, the colours change smoothly and a check mark slides in from the left.
/// The text shortens with "..." when there is not enough room, so nothing overflows.
class ChipBox extends StatelessWidget {
  final String text;
  final bool selected;
  final double height;

  /// Dimmed look for options that do not apply right now.
  final bool muted;

  /// Set to false for labels that are not options, for example a badge.
  final bool showCheck;

  const ChipBox({
    super.key,
    required this.text,
    this.selected = false,
    this.height = 40,
    this.muted = false,
    this.showCheck = true,
  });

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    final Color fg = selected ? c.onAccent : (muted ? c.text3 : c.text);
    final bool check = selected && showCheck;
    return AnimatedContainer(
      duration: kFast,
      curve: kEase,
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: selected ? c.accent : Colors.transparent,
        border: Border.all(color: selected ? c.accent : c.border),
        borderRadius: BorderRadius.circular(kRadius),
      ),
      child: Center(
        widthFactor: 1.0,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AnimatedSize(
              duration: kFast,
              curve: kEase,
              alignment: Alignment.centerLeft,
              child: ClipRect(
                child: Align(
                  alignment: Alignment.centerLeft,
                  widthFactor: check ? 1.0 : 0.0,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(Icons.check, size: 16, color: fg),
                  ),
                ),
              ),
            ),
            Flexible(
              child: AnimatedDefaultTextStyle(
                duration: kFast,
                curve: kEase,
                style: bodyStyle(context, size: 13, weight: FontWeight.w600, color: fg),
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                child: Text(text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows or hides its child with a smooth change of size, so nothing jumps.
class Reveal extends StatelessWidget {
  final bool show;
  final Widget child;

  const Reveal({super.key, required this.show, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: kFast,
      curve: kEase,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: kFast,
        switchInCurve: kEase,
        transitionBuilder: (Widget w, Animation<double> a) => FadeTransition(opacity: a, child: w),
        child: show ? child : const SizedBox(width: double.infinity),
      ),
    );
  }
}

/// A block that grows in when it is added for the first time.
class AppearIn extends StatelessWidget {
  final Widget child;

  const AppearIn({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 240),
      curve: kEase,
      child: child,
      builder: (BuildContext _, double v, Widget? c) {
        return Opacity(
          opacity: v.clamp(0.0, 1.0),
          child: Align(alignment: Alignment.topCenter, heightFactor: v.clamp(0.0, 1.0), child: c),
        );
      },
    );
  }
}

/// Large page title with a small label above it. Tells the user where they are.
class PageHeader extends StatelessWidget {
  final String kicker;
  final String title;
  final Widget? trailing;
  final bool showBack;

  const PageHeader({super.key, required this.kicker, required this.title, this.trailing, this.showBack = false});

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          if (showBack)
            IconButton(
              tooltip: 'Zurück',
              onPressed: () => Navigator.of(context).maybePop(),
              icon: Icon(Icons.arrow_back, color: c.text),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SectionLabel(kicker),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(title.toUpperCase(), style: heading(context, 44)),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

String two(int n) => n < 10 ? '0$n' : '$n';

String formatClock(int seconds) {
  final int s = seconds < 0 ? 0 : seconds;
  return '${two(s ~/ 60)}:${two(s % 60)}';
}

String formatRest(int seconds) {
  if (seconds < 60) {
    return '$seconds s';
  }
  final int m = seconds ~/ 60;
  final int s = seconds % 60;
  return s == 0 ? '$m min' : '$m min $s s';
}

/// Status line for the stretch reminders, used on Home and on the stretch tab.
String reminderLabel(bool enabled, DateTime? next) {
  if (!enabled) {
    return 'Erinnerungen sind aus';
  }
  if (next == null) {
    return 'Keine Erinnerung geplant';
  }
  return 'Nächste Erinnerung: ${weekdayShort[next.weekday - 1]} ${two(next.hour)}:${two(next.minute)}';
}

/// Shared look of text fields.
InputDecoration fieldDecoration(BuildContext context, String label, {String? hint, String? errorText}) {
  final AppColors c = AppColors.of(context);
  OutlineInputBorder border(Color color, double width) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(kRadius),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  return InputDecoration(
    labelText: label,
    hintText: hint,
    errorText: errorText,
    labelStyle: bodyStyle(context, size: 14, color: c.text2),
    hintStyle: bodyStyle(context, size: 15, color: c.text3),
    filled: true,
    fillColor: c.surface,
    enabledBorder: border(c.border, 1),
    focusedBorder: border(c.accentText, 2),
    errorBorder: border(c.text, 1),
    focusedErrorBorder: border(c.text, 2),
  );
}

const List<String> weekdayShort = <String>['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];

/// Lays out options in rows with the same number of columns.
/// Every cell has the same width. A last row with fewer items keeps
/// the same cell width, so nothing breaks unevenly.
class EvenGrid extends StatelessWidget {
  final List<Widget> children;
  final int columns;
  final double gap;

  const EvenGrid({super.key, required this.children, this.columns = 2, this.gap = 8});

  @override
  Widget build(BuildContext context) {
    final List<Widget> rows = <Widget>[];
    for (int i = 0; i < children.length; i += columns) {
      final List<Widget> cells = <Widget>[];
      for (int k = 0; k < columns; k++) {
        if (k > 0) {
          cells.add(SizedBox(width: gap));
        }
        final int index = i + k;
        cells.add(Expanded(child: index < children.length ? children[index] : const SizedBox.shrink()));
      }
      if (rows.isNotEmpty) {
        rows.add(SizedBox(height: gap));
      }
      rows.add(Row(children: cells));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows);
  }
}
