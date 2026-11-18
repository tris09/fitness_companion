import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme.dart';
import '../tutorials.dart';
import 'common.dart';

/// Opens a tutorial as a pop-up over the current screen. The background is
/// blurred. A tap outside or on the close button closes it. One step per page,
/// swipe sideways for the next one.
Future<void> showTutorial(BuildContext context, Tutorial tutorial) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Schließen',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 240),
    pageBuilder: (BuildContext ctx, Animation<double> a, Animation<double> b) => _TutorialPopup(tutorial: tutorial),
    transitionBuilder: (BuildContext ctx, Animation<double> anim, Animation<double> sec, Widget child) {
      final Animation<double> curved = CurvedAnimation(parent: anim, curve: kEase, reverseCurve: Curves.easeIn);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(scale: Tween<double>(begin: 0.96, end: 1.0).animate(curved), child: child),
      );
    },
  );
}

class _TutorialPopup extends StatefulWidget {
  final Tutorial tutorial;

  const _TutorialPopup({required this.tutorial});

  @override
  State<_TutorialPopup> createState() => _TutorialPopupState();
}

class _TutorialPopupState extends State<_TutorialPopup> {
  final PageController _controller = PageController();
  int _page = 0;
  String? _linkError;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _open(String url) async {
    bool ok = false;
    try {
      ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      ok = false;
    }
    if (!ok && mounted) {
      setState(() {
        _linkError = 'Der Link konnte nicht geöffnet werden.';
      });
    }
  }

  void _zoom(TutorialStep step) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Schließen',
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (BuildContext ctx, Animation<double> a, Animation<double> b) => _ImageViewer(step: step),
      transitionBuilder: (BuildContext ctx, Animation<double> anim, Animation<double> sec, Widget child) {
        return FadeTransition(opacity: CurvedAnimation(parent: anim, curve: kEase), child: child);
      },
    );
  }

  Widget _picture(TutorialStep step) {
    final AppColors c = AppColors.of(context);
    return InkWell(
      onTap: () => _zoom(step),
      child: Container(
        decoration: BoxDecoration(border: Border.all(color: c.border), color: c.surface2),
        child: AspectRatio(
          aspectRatio: 4 / 3,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Image.asset(
                step.image,
                fit: BoxFit.cover,
                errorBuilder: (BuildContext _, Object e, StackTrace? s) => Center(
                  child: Text('Bild folgt', style: bodyStyle(context, size: 13, color: c.text3)),
                ),
              ),
              Positioned(
                right: 8,
                bottom: 8,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  color: c.bg,
                  child: Icon(Icons.zoom_out_map, size: 18, color: c.text),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepPage(int i) {
    final AppColors c = AppColors.of(context);
    final TutorialStep step = widget.tutorial.steps[i];
    final int total = widget.tutorial.steps.length;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SectionLabel('Schritt ${i + 1} von $total', color: c.accentText),
          const SizedBox(height: 8),
          Text(step.title.toUpperCase(), style: heading(context, 36)),
          const SizedBox(height: 8),
          Text(step.text, style: bodyStyle(context, size: 15, color: c.text2)),
          if (step.linkUrl != null) ...<Widget>[
            const SizedBox(height: 4),
            InkWell(
              onTap: () => _open(step.linkUrl!),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44),
                child: Row(
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        step.linkLabel ?? step.linkUrl!,
                        style: bodyStyle(context, size: 15, weight: FontWeight.w700, color: c.accentText).copyWith(
                          decoration: TextDecoration.underline,
                          decorationColor: c.accentText,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.north_east, size: 16, color: c.accentText),
                  ],
                ),
              ),
            ),
            if (_linkError != null)
              Text(_linkError!, style: bodyStyle(context, size: 13, weight: FontWeight.w600)),
          ],
          const SizedBox(height: 14),
          _picture(step),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    final int total = widget.tutorial.steps.length;
    final double height = MediaQuery.of(context).size.height;
    return Stack(
      children: <Widget>[
        // Blurred background. A tap on it closes the pop-up.
        Positioned.fill(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: ColoredBox(color: c.bg.withValues(alpha: 0.45)),
            ),
          ),
        ),
        SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 440, maxHeight: height * 0.82),
                child: Material(
                  color: c.bg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(kRadius),
                    side: BorderSide(color: c.accent),
                  ),
                  clipBehavior: Clip.antiAlias,
                  elevation: 8,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 4, 4, 0),
                        child: Row(
                          children: <Widget>[
                            Expanded(child: SectionLabel('Anleitung · ${widget.tutorial.title}')),
                            IconButton(
                              tooltip: 'Schließen',
                              onPressed: () => Navigator.of(context).pop(),
                              icon: Icon(Icons.close, color: c.text),
                            ),
                          ],
                        ),
                      ),
                      Flexible(
                        child: SizedBox(
                          height: height * 0.62,
                          child: PageView.builder(
                            controller: _controller,
                            itemCount: total,
                            onPageChanged: (int i) {
                              setState(() {
                                _page = i;
                                _linkError = null;
                              });
                            },
                            itemBuilder: (BuildContext _, int i) => _stepPage(i),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            for (int i = 0; i < total; i++)
                              AnimatedContainer(
                                duration: kFast,
                                curve: kEase,
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                width: i == _page ? 22 : 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: i == _page ? c.accent : c.border,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Full screen picture. Pinch to zoom, tap or the button to close.
class _ImageViewer extends StatelessWidget {
  final TutorialStep step;

  const _ImageViewer({required this.step});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: SafeArea(
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 5,
                child: Center(
                  child: Image.asset(
                    step.image,
                    fit: BoxFit.contain,
                    errorBuilder: (BuildContext ctx, Object e, StackTrace? s) => Text(
                      'Bild folgt',
                      style: bodyStyle(ctx, size: 15, color: Colors.white70),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        SafeArea(
          child: Align(
            alignment: Alignment.topRight,
            child: IconButton(
              tooltip: 'Schließen',
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
