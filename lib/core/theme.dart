import 'package:flutter/material.dart';

@immutable
class NzPalette extends ThemeExtension<NzPalette> {
  const NzPalette({
    required this.bg,
    required this.surface,
    required this.raise,
    required this.text,
    required this.mute,
    required this.line,
    required this.accent,
    required this.onAccent,
    required this.ok,
    required this.bad,
  });

  final Color bg, surface, raise, text, mute, line, accent, onAccent, ok, bad;

  static const light = NzPalette(
    bg: Color(0xFFFFFFFF),
    surface: Color(0xFFF1F5FF),
    raise: Color(0xFFE1EAFF),
    text: Color(0xFF0B1B3A),
    mute: Color(0xFF5A6A8C),
    line: Color(0xFFD8E1F5),
    accent: Color(0xFF1F5BFF),
    onAccent: Color(0xFFFFFFFF),
    ok: Color(0xFF12814A),
    bad: Color(0xFFC93636),
  );

  static const dark = NzPalette(
    bg: Color(0xFF0A1020),
    surface: Color(0xFF121A30),
    raise: Color(0xFF1B2644),
    text: Color(0xFFEAF0FF),
    mute: Color(0xFF8F9DBF),
    line: Color(0xFF243256),
    accent: Color(0xFF5C93FF),
    onAccent: Color(0xFF06122B),
    ok: Color(0xFF4CC88A),
    bad: Color(0xFFF27A7A),
  );

  @override
  NzPalette copyWith() => this;

  @override
  NzPalette lerp(ThemeExtension<NzPalette>? other, double t) => t < 0.5 ? this : (other as NzPalette? ?? this);
}

extension NzContext on BuildContext {
  NzPalette get nz => Theme.of(this).extension<NzPalette>()!;
}

const displayFont = 'ReadexPro';

// Small-capital letters are missing from the Arabic fonts; Noto Sans is Android's own fallback for them.
const fontFallback = ['NotoSans'];

TextStyle display(NzPalette p, double size, {double weight = 700}) => TextStyle(
  fontFamily: displayFont,
  fontFamilyFallback: fontFallback,
  fontSize: size,
  color: p.text,
  fontVariations: [FontVariation('wght', weight)],
  height: 1.3,
);

ThemeData buildTheme(NzPalette p, Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: p.accent,
    brightness: brightness,
  ).copyWith(primary: p.accent, onPrimary: p.onAccent, surface: p.bg, onSurface: p.text, error: p.bad);
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: p.bg,
    fontFamily: 'IBMPlexSansArabic',
    fontFamilyFallback: fontFallback,
    extensions: [p],
    textTheme: ThemeData(brightness: brightness).textTheme.apply(
      fontFamily: 'IBMPlexSansArabic',
      fontFamilyFallback: fontFallback,
      bodyColor: p.text,
      displayColor: p.text,
    ),
    dividerColor: p.line,
    snackBarTheme: SnackBarThemeData(
      backgroundColor: p.raise,
      contentTextStyle: TextStyle(color: p.text, fontFamily: 'IBMPlexSansArabic', fontSize: 14),
      behavior: SnackBarBehavior.floating,
    ),
    dialogTheme: DialogThemeData(backgroundColor: p.bg, surfaceTintColor: Colors.transparent),
  );
}
