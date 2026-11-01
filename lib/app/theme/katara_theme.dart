import 'package:flutter/material.dart';
import 'package:katara/app/theme/katara_colors.dart';

class KataraTypography {
  const KataraTypography._();

  static const String uiFont = 'Nunito';
  static const String jawiFont = 'Noto Naskh Arabic';

  static TextStyle display(Color color) => TextStyle(
        fontFamily: uiFont,
        fontSize: 30,
        fontWeight: FontWeight.w800,
        height: 1.2,
        color: color,
      );

  static TextStyle title(Color color) => TextStyle(
        fontFamily: uiFont,
        fontSize: 21,
        fontWeight: FontWeight.w700,
        height: 1.3,
        color: color,
      );

  static TextStyle body(Color color) => TextStyle(
        fontFamily: uiFont,
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.45,
        color: color,
      );

  static TextStyle label(Color color) => TextStyle(
        fontFamily: uiFont,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: color,
      );

  static TextStyle jawi({
    required Color color,
    double fontSize = 32,
    FontWeight fontWeight = FontWeight.w700,
  }) =>
      TextStyle(
        fontFamily: jawiFont,
        fontSize: fontSize,
        fontWeight: fontWeight,
        height: 1.6,
        color: color,
      );
}

class KataraTheme {
  const KataraTheme._();

  static ThemeData light() => _build(Brightness.light, KataraPalette.light);
  static ThemeData dark() => _build(Brightness.dark, KataraPalette.dark);

  static ThemeData _build(Brightness brightness, KataraPalette p) {
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: p.primary,
      onPrimary: p.onPrimary,
      secondary: p.secondary,
      onSecondary: p.onSecondary,
      error: p.error,
      onError: Colors.white,
      surface: p.surface,
      onSurface: p.ink,
      outline: p.outline,
      surfaceContainerHighest: p.surfaceAlt,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: KataraTypography.uiFont,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: p.bg,
      extensions: <ThemeExtension<dynamic>>[p],
      appBarTheme: AppBarTheme(
        backgroundColor: p.bg,
        foregroundColor: p.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: KataraTypography.title(p.ink),
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: p.outline, width: 1.5),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: p.outline,
        thickness: 1.2,
      ),
      textTheme: TextTheme(
        displayLarge: KataraTypography.display(p.ink),
        headlineMedium: KataraTypography.display(p.ink).copyWith(fontSize: 28),
        titleLarge: KataraTypography.title(p.ink),
        titleMedium: KataraTypography.title(p.ink).copyWith(fontSize: 18),
        bodyLarge: KataraTypography.body(p.ink),
        bodyMedium: KataraTypography.body(p.ink).copyWith(fontSize: 15),
        bodySmall: KataraTypography.label(p.inkMuted),
        labelLarge: KataraTypography.label(p.ink).copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
        labelMedium: KataraTypography.label(p.inkMuted),
      ),
    );
  }
}
