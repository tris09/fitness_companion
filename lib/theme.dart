import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Colour tokens of the app. One set per style; read via [AppColors.of].
class AppColors extends ThemeExtension<AppColors> {
  final Color bg;
  final Color surface;
  final Color surface2;
  final Color border;
  final Color text;
  final Color text2;
  final Color text3;

  /// Strong fill for buttons, selected chips and highlights.
  final Color accent;
  final Color onAccent;

  /// Text or icon that has to stand out. Never lime on light backgrounds.
  final Color accentText;
  final Color figBase;
  final Color figOn;

  /// Lime highlight block (day plan card, today, badges). Always lime.
  final Color lime;

  /// Mark for "training planned" under a day.
  final Color strike;

  /// Coloured title bar behind the tab titles. Null = no bar.
  final Color? band;
  final Color bandText;
  final Color bandText2;

  /// Background of the bottom bar. Differs from [bg].
  final Color navBar;

  /// Active tab in the bottom bar.
  final Color navActiveBg;
  final Color navActiveFg;

  /// Thin line on top of the active tab.
  final Color navLine;
  final bool navFullLine;

  /// Background of the news area at the bottom of Home.
  final Color newsBg;

  /// Error colour for text, icons and borders, and its light fill.
  final Color error;
  final Color errorBg;

  /// Stronger edge for tappable controls (chips, outlined buttons, fields).
  /// Null = same as [border].
  final Color? controlBorder;
  Color get outline => controlBorder ?? border;

  /// Fill of fields and outlined buttons/chips. Never the colour of the cards.
  /// Null = [surface] (high contrast).
  final Color? controlFill;
  Color get control => controlFill ?? surface;

  /// Dark edge around lime fills on light backgrounds. Null = no edge.
  final Color? accentEdge;

  /// Border width of cards. 2 in high contrast.
  final double borderWidth;
  final bool highContrast;

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
    this.lime = const Color(0xFFC6FF00),
    required this.strike,
    this.band,
    this.bandText = const Color(0xFFFFFFFF),
    this.bandText2 = const Color(0xFFA3A9AF),
    required this.navBar,
    required this.navActiveBg,
    required this.navActiveFg,
    required this.navLine,
    required this.navFullLine,
    required this.newsBg,
    this.error = const Color(0xFFC62117),
    this.errorBg = const Color(0xFFFDECEA),
    this.controlBorder,
    this.controlFill,
    this.accentEdge,
    this.borderWidth = 1,
    this.highContrast = false,
  });

  bool get isDark => bg.computeLuminance() < 0.2;

  // ---- dark styles ----
  static const AppColors darkBlack = AppColors(
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
    strike: Color(0xFFC6FF00),
    band: Color(0xFF1F2327),
    navBar: Color(0xFF17191B),
    navActiveBg: Color(0x00000000),
    navActiveFg: Color(0xFFC6FF00),
    navLine: Color(0xFFC6FF00),
    navFullLine: false,
    newsBg: Color(0xFF222528),
    error: Color(0xFFFF6B5B),
    errorBg: Color(0xFF2B1614),
    controlBorder: Color(0xFF6E747A),
    controlFill: Color(0xFF212427),
  );

  static const AppColors darkGrey = AppColors(
    bg: Color(0xFF1C1F22),
    surface: Color(0xFF272B2F),
    surface2: Color(0xFF31363B),
    border: Color(0xFF3D4349),
    text: Color(0xFFFFFFFF),
    text2: Color(0xFFB4B8BC),
    text3: Color(0xFF9CA1A7),
    accent: Color(0xFFC6FF00),
    onAccent: Color(0xFF0D0E0F),
    accentText: Color(0xFFC6FF00),
    figBase: Color(0xFF4A4F57),
    figOn: Color(0xFFC6FF00),
    strike: Color(0xFFC6FF00),
    band: Color(0xFF2E3337),
    navBar: Color(0xFF2A2E33),
    navActiveBg: Color(0x00000000),
    navActiveFg: Color(0xFFC6FF00),
    navLine: Color(0xFFC6FF00),
    navFullLine: false,
    newsBg: Color(0xFF151719),
    error: Color(0xFFFF6B5B),
    errorBg: Color(0xFF2B1614),
    controlBorder: Color(0xFF7C838A),
    controlFill: Color(0xFF31363B),
  );

  static const AppColors darkBlue = AppColors(
    bg: Color(0xFF0B1322),
    surface: Color(0xFF142038),
    surface2: Color(0xFF1B2A47),
    border: Color(0xFF283A5C),
    text: Color(0xFFFFFFFF),
    text2: Color(0xFFB5C2D8),
    text3: Color(0xFF8496B5),
    accent: Color(0xFFC6FF00),
    onAccent: Color(0xFF0D0E0F),
    accentText: Color(0xFFC6FF00),
    figBase: Color(0xFF3A4A68),
    figOn: Color(0xFFC6FF00),
    strike: Color(0xFFC6FF00),
    band: Color(0xFF1D2D4D),
    navBar: Color(0xFF16233D),
    navActiveBg: Color(0x00000000),
    navActiveFg: Color(0xFFC6FF00),
    navLine: Color(0xFFC6FF00),
    navFullLine: false,
    newsBg: Color(0xFF08101C),
    error: Color(0xFFFF6B5B),
    errorBg: Color(0xFF2B1620),
    controlBorder: Color(0xFF6378A6),
    controlFill: Color(0xFF1B2A47),
  );

  static const AppColors darkContrast = AppColors(
    bg: Color(0xFF000000),
    surface: Color(0xFF000000),
    surface2: Color(0xFF000000),
    border: Color(0xFFFFFFFF),
    text: Color(0xFFFFFFFF),
    text2: Color(0xFFFFFFFF),
    text3: Color(0xFFFFFFFF),
    accent: Color(0xFFC6FF00),
    onAccent: Color(0xFF000000),
    accentText: Color(0xFFFFFFFF),
    figBase: Color(0xFF6A6A6A),
    figOn: Color(0xFFC6FF00),
    strike: Color(0xFFFFFFFF),
    navBar: Color(0xFF000000),
    navActiveBg: Color(0xFFFFFFFF),
    navActiveFg: Color(0xFF000000),
    navLine: Color(0xFFC6FF00),
    navFullLine: true,
    newsBg: Color(0xFF000000),
    borderWidth: 2,
    highContrast: true,
    error: Color(0xFFFF6B5B),
    errorBg: Color(0xFF000000),
  );

  // ---- light styles ----
  static const AppColors lightStone = AppColors(
    bg: Color(0xFFECECE8),
    surface: Color(0xFFF6F6F3),
    surface2: Color(0xFFE2E2DD),
    border: Color(0xFFCDCDC7),
    text: Color(0xFF0D0E0F),
    text2: Color(0xFF4A4D52),
    text3: Color(0xFF5A5D62),
    accent: Color(0xFFC6FF00),
    onAccent: Color(0xFF0D0E0F),
    accentText: Color(0xFF0D0E0F),
    figBase: Color(0xFFB4B6BA),
    figOn: Color(0xFF0D0E0F),
    strike: Color(0xFF0D0E0F),
    band: Color(0xFF1E2124),
    navBar: Color(0xFFFFFFFF),
    navActiveBg: Color(0xFFE2E2DD),
    navActiveFg: Color(0xFF0D0E0F),
    navLine: Color(0xFFC6FF00),
    navFullLine: true,
    newsBg: Color(0xFFDBDBD4),
    controlBorder: Color(0xFF82827D),
    accentEdge: Color(0xFF0D0E0F),
    controlFill: Color(0xFFFFFFFF),
  );

  static const AppColors lightWhite = AppColors(
    bg: Color(0xFFFFFFFF),
    surface: Color(0xFFF4F4F2),
    surface2: Color(0xFFE9E9E6),
    border: Color(0xFFC9C9C4),
    text: Color(0xFF0D0E0F),
    text2: Color(0xFF4A4D52),
    text3: Color(0xFF63666B),
    accent: Color(0xFFC6FF00),
    onAccent: Color(0xFF0D0E0F),
    accentText: Color(0xFF0D0E0F),
    figBase: Color(0xFFC4C6CA),
    figOn: Color(0xFF0D0E0F),
    strike: Color(0xFF0D0E0F),
    band: Color(0xFF1E2124),
    navBar: Color(0xFFF4F4F2),
    navActiveBg: Color(0xFFE2E2DD),
    navActiveFg: Color(0xFF0D0E0F),
    navLine: Color(0xFFC6FF00),
    navFullLine: true,
    newsBg: Color(0xFFECECE8),
    controlBorder: Color(0xFF8F8F8A),
    accentEdge: Color(0xFF0D0E0F),
    controlFill: Color(0xFFFFFFFF),
  );

  static const AppColors lightBlue = AppColors(
    bg: Color(0xFFEAF0F7),
    surface: Color(0xFFF4F7FB),
    surface2: Color(0xFFDCE5F0),
    border: Color(0xFFC2CEDE),
    text: Color(0xFF0B1626),
    text2: Color(0xFF3D4B60),
    text3: Color(0xFF4F5F75),
    accent: Color(0xFFC6FF00),
    onAccent: Color(0xFF0D0E0F),
    accentText: Color(0xFF0B1626),
    figBase: Color(0xFFB0BBCB),
    figOn: Color(0xFF0B1626),
    strike: Color(0xFF0B1626),
    band: Color(0xFF0F1D33),
    navBar: Color(0xFFFFFFFF),
    navActiveBg: Color(0xFFDCE5F0),
    navActiveFg: Color(0xFF0B1626),
    navLine: Color(0xFFC6FF00),
    navFullLine: true,
    newsBg: Color(0xFFD5DFEB),
    controlBorder: Color(0xFF6E7E95),
    accentEdge: Color(0xFF0B1626),
    controlFill: Color(0xFFFFFFFF),
  );

  static const AppColors lightContrast = AppColors(
    bg: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFFFFFFF),
    border: Color(0xFF000000),
    text: Color(0xFF000000),
    text2: Color(0xFF000000),
    text3: Color(0xFF000000),
    accent: Color(0xFF000000),
    onAccent: Color(0xFFFFFFFF),
    accentText: Color(0xFF000000),
    figBase: Color(0xFFBDBDBD),
    figOn: Color(0xFF000000),
    strike: Color(0xFF000000),
    navBar: Color(0xFFFFFFFF),
    navActiveBg: Color(0xFF000000),
    navActiveFg: Color(0xFFFFFFFF),
    navLine: Color(0xFF000000),
    navFullLine: true,
    newsBg: Color(0xFFFFFFFF),
    borderWidth: 2,
    highContrast: true,
    error: Color(0xFFB00000),
    errorBg: Color(0xFFFFFFFF),
  );

  /// Kept for code that asks for the default sets directly.
  static const AppColors dark = darkBlack;
  static const AppColors light = lightWhite;

  static AppColors of(BuildContext context) {
    final ThemeData t = Theme.of(context);
    return t.extension<AppColors>() ?? (t.brightness == Brightness.dark ? dark : light);
  }

  /// Picks the colour set for a brightness and the user's choices.
  static AppColors pick(Brightness b, {String lightStyle = 'white', String darkStyle = 'black', bool highContrast = false}) {
    if (b == Brightness.dark) {
      if (highContrast) {
        return darkContrast;
      }
      return darkStyle == 'grey' ? darkGrey : (darkStyle == 'blue' ? darkBlue : darkBlack);
    }
    if (highContrast) {
      return lightContrast;
    }
    return lightStyle == 'stone' ? lightStone : (lightStyle == 'blue' ? lightBlue : lightWhite);
  }

  /// Same set with the text colours of the title bar. Used inside the bar.
  /// Default accent (lime). A custom accent replaces every use of it.
  static const Color defaultAccent = Color(0xFFC6FF00);

  /// Readable text colour on the accent fill: ink on light accents, white on dark ones.
  Color get onLime => lime.computeLuminance() > 0.35 ? const Color(0xFF0D0E0F) : const Color(0xFFFFFFFF);

  static double _contrast(Color a, Color b) {
    final double la = a.computeLuminance();
    final double lb = b.computeLuminance();
    return (la > lb ? la + 0.05 : lb + 0.05) / (la > lb ? lb + 0.05 : la + 0.05);
  }

  /// Same colours with another accent. Every place that used lime gets [a].
  /// Where the accent is used as text or line on the page it must stay readable:
  /// below 3:1 against the background the normal text colour is used instead.
  AppColors withAccent(Color a) {
    if (a.toARGB32() == defaultAccent.toARGB32()) {
      return this;
    }
    Color sw(Color c) => c.toARGB32() == defaultAccent.toARGB32() ? a : c;
    Color? sw2(Color? c) => c == null ? null : sw(c);
    final AppColors raw = AppColors(
      bg: bg,
      surface: sw(surface),
      surface2: sw(surface2),
      border: sw(border),
      text: sw(text),
      text2: sw(text2),
      text3: sw(text3),
      accent: sw(accent),
      onAccent: sw(onAccent),
      accentText: sw(accentText),
      figBase: sw(figBase),
      figOn: sw(figOn),
      lime: sw(lime),
      strike: sw(strike),
      band: sw2(band),
      bandText: sw(bandText),
      bandText2: sw(bandText2),
      navBar: sw(navBar),
      navActiveBg: sw(navActiveBg),
      navActiveFg: sw(navActiveFg),
      navLine: sw(navLine),
      newsBg: sw(newsBg),
      error: sw(error),
      errorBg: sw(errorBg),
      controlBorder: sw2(controlBorder),
      controlFill: sw2(controlFill),
      accentEdge: sw2(accentEdge),
      navFullLine: navFullLine,
      borderWidth: borderWidth,
      highContrast: highContrast,
    );
    final bool readable = _contrast(a, bg) >= 3;
    final Color on = a.computeLuminance() > 0.35 ? const Color(0xFF0D0E0F) : const Color(0xFFFFFFFF);
    return AppColors(
      bg: raw.bg,
      surface: raw.surface,
      surface2: raw.surface2,
      border: raw.border,
      text: raw.text,
      text2: raw.text2,
      text3: raw.text3,
      accent: raw.accent,
      onAccent: raw.accent == a ? on : raw.onAccent,
      accentText: raw.accentText == a && !readable ? raw.text : raw.accentText,
      figBase: raw.figBase,
      figOn: raw.figOn == a && !readable ? raw.text : raw.figOn,
      lime: raw.lime,
      strike: raw.strike == a && !readable ? raw.text : raw.strike,
      band: raw.band,
      bandText: raw.bandText,
      bandText2: raw.bandText2,
      navBar: raw.navBar,
      navActiveBg: raw.navActiveBg,
      navActiveFg: raw.navActiveFg == a && _contrast(a, raw.navBar) < 3 ? raw.text : raw.navActiveFg,
      navLine: raw.navLine,
      navFullLine: raw.navFullLine,
      newsBg: raw.newsBg,
      error: raw.error,
      errorBg: raw.errorBg,
      controlBorder: raw.controlBorder,
      controlFill: raw.controlFill,
      accentEdge: raw.accentEdge,
      borderWidth: raw.borderWidth,
      highContrast: raw.highContrast,
    );
  }

  AppColors forBand() {
    return AppColors(
      bg: band ?? bg,
      surface: surface,
      surface2: surface2,
      border: border,
      text: bandText,
      text2: bandText2,
      text3: bandText2,
      accent: accent,
      onAccent: onAccent,
      accentText: lime,
      figBase: figBase,
      figOn: figOn,
      lime: lime,
      strike: strike,
      band: band,
      bandText: bandText,
      bandText2: bandText2,
      navBar: navBar,
      navActiveBg: navActiveBg,
      navActiveFg: navActiveFg,
      navLine: navLine,
      navFullLine: navFullLine,
      newsBg: newsBg,
      error: error,
      errorBg: errorBg,
      controlBorder: controlBorder,
      controlFill: controlFill,
      accentEdge: accentEdge,
      borderWidth: borderWidth,
      highContrast: highContrast,
    );
  }

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    // Colour sets switch at once; no blending needed.
    if (other is! AppColors) {
      return this;
    }
    return t < 0.5 ? this : other;
  }
}

/// Colours of the training screens. Always dark, never pure black.
const AppColors kTrainingColors = AppColors(
  bg: Color(0xFF1B1E21),
  surface: Color(0xFF25292D),
  surface2: Color(0xFF30353A),
  border: Color(0xFF41474D),
  text: Color(0xFFFFFFFF),
  text2: Color(0xFFD0D4D8),
  text3: Color(0xFFA3A9AF),
  accent: Color(0xFFC6FF00),
  onAccent: Color(0xFF0D0E0F),
  accentText: Color(0xFFC6FF00),
  figBase: Color(0xFF4A4F57),
  figOn: Color(0xFFC6FF00),
  strike: Color(0xFFC6FF00),
  navBar: Color(0xFF1B1E21),
  navActiveBg: Color(0x00000000),
  navActiveFg: Color(0xFFC6FF00),
  navLine: Color(0xFFC6FF00),
  navFullLine: false,
  newsBg: Color(0xFF25292D),
  error: Color(0xFFFF6B5B),
  errorBg: Color(0xFF2B1614),
  controlBorder: Color(0xFF747A80),
  controlFill: Color(0xFF30353A),
);

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

ThemeData buildTheme(Brightness brightness, {AppColors? colors}) {
  final AppColors c = colors ?? (brightness == Brightness.dark ? AppColors.dark : AppColors.light);
  final ThemeData base = ThemeData(brightness: brightness, useMaterial3: true);
  return base.copyWith(
    extensions: <ThemeExtension<dynamic>>[c],
    scaffoldBackgroundColor: c.bg,
    colorScheme: base.colorScheme.copyWith(
      primary: c.accent,
      onPrimary: c.onAccent,
      secondary: c.accent,
      onSecondary: c.onAccent,
      surface: c.surface,
      onSurface: c.text,
      error: c.error,
      onError: const Color(0xFFFFFFFF),
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
    switchTheme: _switchTheme(c, brightness),
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

/// One look for every switch. The thumb is always dark on lime, also when the
/// switch is locked. Light themes get a dark outline, so lime and the light
/// background do not blend into each other.
SwitchThemeData _switchTheme(AppColors c, Brightness brightness) {
  final bool light = brightness == Brightness.light;
  final Color offThumbLight = c.highContrast ? c.text : const Color(0xFF55554F);
  return SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((Set<WidgetState> s) {
      if (s.contains(WidgetState.selected)) {
        return c.onAccent;
      }
      return light ? offThumbLight : c.text2;
    }),
    trackColor: WidgetStateProperty.resolveWith((Set<WidgetState> s) {
      if (s.contains(WidgetState.selected)) {
        return c.accent;
      }
      return light ? c.surface : c.surface2;
    }),
    trackOutlineColor: WidgetStateProperty.resolveWith((Set<WidgetState> s) {
      if (s.contains(WidgetState.selected)) {
        return light ? c.onAccent : Colors.transparent;
      }
      return light ? offThumbLight : c.text3;
    }),
    trackOutlineWidth: WidgetStateProperty.all<double>(2),
    overlayColor: WidgetStateProperty.all<Color>(Colors.transparent),
  );
}
