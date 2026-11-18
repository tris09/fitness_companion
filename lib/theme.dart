import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Colour tokens of the app. One set per mode.
class AppColors {
  final Color bg;
  final Color surface;
  final Color surface2;
  final Color border;
  final Color text;
  final Color text2;
  final Color text3;
  final Color accent;
  final Color onAccent;
  final Color accentText;
  final Color figBase;
  final Color figOn;

  const AppColors({
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.border,
    required this.text,
    required this.text2,
    required this.text3,
    required this.accent,
    required this.onAccent,
    required this.accentText,
    required this.figBase,
    required this.figOn,
  });

  static const AppColors dark = AppColors(
    bg: Color(0xFF0D0E0F),
    surface: Color(0xFF17191B),
    surface2: Color(0xFF212427),
    border: Color(0xFF33373B),
    text: Color(0xFFFFFFFF),
    text2: Color(0xFFB4B8BC),
    text3: Color(0xFF8E9399),
    accent: Color(0xFFC6FF00),
    onAccent: Color(0xFF0D0E0F),
    accentText: Color(0xFFC6FF00),
    figBase: Color(0xFF4A4F57),
    figOn: Color(0xFFC6FF00),
  );

  static const AppColors light = AppColors(
    bg: Color(0xFFFFFFFF),
    surface: Color(0xFFF4F4F2),
    surface2: Color(0xFFE9E9E6),
    border: Color(0xFFCFCFCB),
    text: Color(0xFF0D0E0F),
    text2: Color(0xFF4A4D52),
    text3: Color(0xFF63666B),
    accent: Color(0xFF0D0E0F),
    onAccent: Color(0xFFC6FF00),
    accentText: Color(0xFF4D6600),
    figBase: Color(0xFFC4C6CA),
    figOn: Color(0xFF6E9100),
  );

  static AppColors of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }
}

const double kRadius = 2;

/// Duration and curve used for all small state changes (selection, resizing).
const Duration kFast = Duration(milliseconds: 200);
const Curve kEase = Curves.easeOutCubic;

/// Screen change: the new screen slides in a little from the right and fades in,
/// the old one moves a little to the left. Shows the user where they are going.
class AppPageTransitions extends PageTransitionsBuilder {
  const AppPageTransitions();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final Animation<Offset> slideIn = animation.drive(
      Tween<Offset>(begin: const Offset(0.10, 0), end: Offset.zero).chain(CurveTween(curve: Curves.easeOutCubic)),
    );
    final Animation<double> fadeIn = animation.drive(CurveTween(curve: Curves.easeOut));
    final Animation<Offset> slideOut = secondaryAnimation.drive(
      Tween<Offset>(begin: Offset.zero, end: const Offset(-0.05, 0)).chain(CurveTween(curve: Curves.easeOutCubic)),
    );
    return SlideTransition(
      position: slideOut,
      child: FadeTransition(
        opacity: fadeIn,
        child: SlideTransition(position: slideIn, child: child),
      ),
    );
  }
}

ThemeData buildTheme(Brightness brightness) {
  final AppColors c = brightness == Brightness.dark ? AppColors.dark : AppColors.light;
  final ThemeData base = ThemeData(brightness: brightness, useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: c.bg,
    colorScheme: base.colorScheme.copyWith(
      primary: c.accent,
      onPrimary: c.onAccent,
      secondary: c.accent,
      onSecondary: c.onAccent,
      surface: c.surface,
      onSurface: c.text,
    ),
    textTheme: base.textTheme.apply(
      fontFamily: GoogleFonts.inter().fontFamily,
      bodyColor: c.text,
      displayColor: c.text,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: <TargetPlatform, PageTransitionsBuilder>{
        TargetPlatform.android: AppPageTransitions(),
        TargetPlatform.iOS: AppPageTransitions(),
      },
    ),
    dividerColor: c.border,
    splashFactory: NoSplash.splashFactory,
    popupMenuTheme: PopupMenuThemeData(
      color: c.surface2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kRadius),
        side: BorderSide(color: c.border),
      ),
    ),
  );
}

/// Condensed heading style. Pass already upper-cased text.
TextStyle heading(BuildContext context, double size, {Color? color}) {
  return GoogleFonts.barlowCondensed(
    fontSize: size,
    fontWeight: FontWeight.w700,
    height: 1.0,
    letterSpacing: 0.2,
    color: color ?? AppColors.of(context).text,
  );
}

/// Small tracked label style. Pass already upper-cased text.
TextStyle labelStyle(BuildContext context, {Color? color}) {
  return GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.9,
    height: 1.2,
    color: color ?? AppColors.of(context).text3,
  );
}

TextStyle bodyStyle(BuildContext context, {double size = 15, Color? color, FontWeight weight = FontWeight.w400}) {
  return GoogleFonts.inter(
    fontSize: size,
    fontWeight: weight,
    height: 1.4,
    color: color ?? AppColors.of(context).text,
  );
}
